import copy
import json
import sys
import os
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FRAMEWORK=Path(os.environ.get('SCENEZOI_REPO',str(ROOT.parent/'SceneZOI')))
sys.path.insert(0,str(FRAMEWORK/'tools'))
from build_catalog import compile_packs, lua
from pack_sources import load_pack


class CatalogTests(unittest.TestCase):
    def setUp(self):
        self.packs = [json.loads(p.read_text(encoding='utf-8')) for p in sorted((ROOT / 'tests/fixtures/legacy-packs').glob('*.json'))]

    def test_neutral_framework_without_hzoi(self):
        neutral = next(p for p in self.packs if p['id'] == 'scenezoi')
        result = compile_packs([neutral])
        self.assertEqual(list(result['nodes']), ['scenezoi.standing_idle'])
        text = lua(result)
        self.assertNotIn('HZoi', text)
        self.assertNotIn('attachment', text)

    def test_all_sets_and_external_hub_extension(self):
        nodes = compile_packs(self.packs)['nodes']
        self.assertEqual(len(nodes), 5)
        self.assertEqual(nodes['scenezoi.standing_idle']['navigation'][0]['target'], 'hzoi.standing_idle')
        self.assertEqual(len(nodes['hzoi.standing_idle']['navigation']), 4)
        self.assertEqual(nodes['scenezoi.standing_idle']['attachments']['male_anatomy']['mesh'], nodes['hzoi.standing_idle']['attachments']['male_anatomy']['mesh'])

    def test_hub_attachment_provider_validation(self):
        hzoi = next(p for p in self.packs if p['id'] == 'hzoi')
        for change in [dict(hub='missing.node'), dict(source='scenezoi.standing_idle'), dict(source='hzoi.missing')]:
            packs = copy.deepcopy(self.packs)
            pack = next(p for p in packs if p['id'] == 'hzoi')
            pack['attachment_extensions'][0].update(change)
            with self.assertRaises(ValueError): compile_packs(packs)
        hzoi['attachment_extensions'].append(dict(hzoi['attachment_extensions'][0]))
        with self.assertRaises(ValueError): compile_packs(self.packs)

    def test_hub_attachment_provider_is_conditional_and_uses_hub_role(self):
        neutral = next(p for p in self.packs if p['id'] == 'scenezoi')['nodes'][0]
        neutral['participants'] = {'actor_a': {'body':'male'}, 'actor_b': {'body':'female'}}
        # Role identities are fixed across navigation. Test the provider independently.
        hzoi = next(p for p in self.packs if p['id']=='hzoi')
        hzoi['extensions'] = []
        hzoi['attachment_extensions'][0]['participant'] = 'actor_a'
        neutral['tracks'] = {'actor_a':neutral['tracks']['male'], 'actor_b':neutral['tracks']['female']}
        neutral['expressions'] = {'actor_a': neutral['expressions']['male'], 'actor_b': neutral['expressions']['female']}
        neutral['anchor_participant'] = 'actor_a'
        neutral['gaze'] = {'actor_a': dict(neutral['gaze']['male'], participant='actor_b'),
                           'actor_b': dict(neutral['gaze']['female'], participant='actor_a')}
        before = copy.deepcopy(self.packs)
        for n in hzoi['nodes']:
            n['navigation'] = [e for e in n['navigation'] if e['target'] != neutral['id']]
        before = copy.deepcopy(self.packs)
        nodes = compile_packs(self.packs)['nodes']
        self.assertEqual(nodes[neutral['id']]['attachments']['male_anatomy']['participant'], 'actor_a')
        self.assertEqual(self.packs, before)
        hzoi = next(p for p in self.packs if p['id'] == 'hzoi')
        hzoi['nodes'][0]['attachments']['male_anatomy']['when_undressed'] = False
        with self.assertRaises(ValueError): compile_packs(self.packs)

    def test_demo_navigation_and_persistent_outfit_contract(self):
        nodes = compile_packs(self.packs)['nodes']
        hub, idle = nodes['scenezoi.standing_idle'], nodes['hzoi.standing_idle']
        self.assertEqual(hub['label'], 'Standing Idle Hub')
        self.assertEqual(idle['label'], 'HZoi Standing Idle')
        self.assertEqual([e['target'] for e in hub['navigation']], [idle['id']])
        self.assertNotIn('outfits', hub)
        self.assertNotIn('outfits', idle)
        self.assertNotEqual(hub['tracks'], idle['tracks'])
        self.assertEqual(idle['navigation'][0]['label'], 'Return...')
        scenes = ['hzoi.standing_hand_job', 'hzoi.standing_kneeling', 'hzoi.standing_rear']
        self.assertEqual({e['target'] for e in idle['navigation']}, {hub['id'], *scenes})
        for scene in scenes:
            self.assertEqual([e['target'] for e in nodes[scene]['navigation']], [idle['id']])
            self.assertEqual(nodes[scene]['navigation'][0]['label'], 'Return...')
            roles = {'male', 'female'} if scene.endswith('rear') else {'male'}
            self.assertEqual(set(nodes[scene]['outfits']), roles)
        for node in [idle] + [nodes[s] for s in scenes]:
            spec = node['attachments']['male_anatomy']
            self.assertIs(spec['when_undressed'], True)
            self.assertIs(spec['retain_for_session'], True)
            self.assertEqual(set(spec['retained_tracks']), {hub['id'], idle['id']})

    def test_invalid_retention_conditions_and_targets_rejected(self):
        spec = self.packs[0]['nodes'][0]['attachments']['male_anatomy']
        spec['when_undressed'] = 'true'
        with self.assertRaises(ValueError): compile_packs(self.packs)
        self.setUp()
        spec = self.packs[0]['nodes'][0]['attachments']['male_anatomy']
        spec['retained_tracks']['missing.node'] = spec['animation']
        with self.assertRaises(ValueError): compile_packs(self.packs)

    def test_navigation_caption_falls_back_to_destination_name(self):
        for value in ['omitted', None, '', '   ']:
            self.setUp()
            hzoi = next(p for p in self.packs if p['id'] == 'hzoi')
            edge = hzoi['nodes'][0]['navigation'][0]
            extension = hzoi['extensions'][0]
            if value == 'omitted':
                edge.pop('label', None); extension.pop('label', None)
            else:
                edge['label'] = value; extension['label'] = value
            before = copy.deepcopy(self.packs)
            nodes = compile_packs(self.packs)['nodes']
            self.assertEqual(nodes['hzoi.standing_idle']['navigation'][0]['label'], 'Standing Idle Hub')
            self.assertEqual(nodes['scenezoi.standing_idle']['navigation'][0]['label'], 'HZoi Standing Idle')
            self.assertEqual(self.packs, before, 'Resolving labels must not mutate authored data')

    def test_custom_navigation_caption_validation(self):
        for value in [7, False, 'line\nbreak', 'x' * 101]:
            self.setUp()
            self.packs[0]['nodes'][0]['navigation'][0]['label'] = value
            with self.assertRaises(ValueError): compile_packs(self.packs)
        self.setUp()
        self.packs[0]['nodes'][0]['navigation'][0]['label'] = 'Back <to idle> & rest'
        nodes = compile_packs(self.packs)['nodes']
        self.assertEqual(nodes['hzoi.standing_idle']['navigation'][0]['label'], 'Back <to idle> & rest')
        self.setUp()
        self.packs[0]['nodes'][0]['label'] = '   '
        with self.assertRaises(ValueError): compile_packs(self.packs)

    def test_unknown_executable_fields_rejected(self):
        self.packs[0]['nodes'][0]['on_enter'] = 'print("injected")'
        with self.assertRaises(ValueError): compile_packs(self.packs)

    def test_broken_navigation_rejected(self):
        self.packs[0]['nodes'][0]['navigation'][0]['target'] = 'missing.node'
        with self.assertRaises(ValueError): compile_packs(self.packs)

    def test_duplicate_namespaces_rejected(self):
        with self.assertRaises(ValueError): compile_packs(self.packs + [copy.deepcopy(self.packs[0])])

    def test_invalid_profile_and_slots_rejected(self):
        self.packs[0]['nodes'][0]['attachments']['male_anatomy']['body_profile'] = 'invalid profile()'
        with self.assertRaises(ValueError): compile_packs(self.packs)
        self.setUp()
        self.packs[0]['nodes'][1]['outfits']['male']['remove_slots'].append('Anything')
        with self.assertRaises(ValueError): compile_packs(self.packs)

    def test_source_inventory_matches_import_plan(self):
        inventory = {x['filename']: x for x in json.loads((ROOT / 'animation-inventory.json').read_text(encoding='utf-8'))}
        imports = json.loads((ROOT / 'imports.json').read_text(encoding='utf-8'))
        self.assertEqual(len(inventory), 13)
        self.assertEqual(len(imports), 13)
        self.assertEqual({x['source'] for x in imports}, set(inventory))
        for entry in imports:
            clip = inventory[entry['source']]
            self.assertEqual(clip['fps'], 60)
            self.assertEqual(clip['limb_node_count'], 7 if entry['skeleton'] == 'attachment' else 80)
            take = clip['takes'][0]
            self.assertEqual(take['start_frame'], 0)
            self.assertEqual(take['end_frame'], 240 if entry['source']=='HZoi bed idle MA.fbx' else 180 if 'idle' in entry['source'] else 600)

    def test_named_roles_are_independent_of_body_labels(self):
        pack = next(p for p in self.packs if p['id'] == 'scenezoi')
        node = pack['nodes'][0]
        node.pop('sfx', None)
        node['participants'] = {'actor_a': {'body': 'male'}, 'actor_b': {'body': 'female'}}
        node['tracks'] = {'actor_a': node['tracks']['male'], 'actor_b': node['tracks']['female']}
        node['expressions'] = {'actor_a': node['expressions']['male'], 'actor_b': node['expressions']['female']}
        node['anchor_participant'] = 'actor_b'
        node['gaze'] = {'actor_a': dict(node['gaze']['male'], participant='actor_b'),
                        'actor_b': dict(node['gaze']['female'], participant='actor_a')}
        compiled = compile_packs([pack])
        self.assertEqual(compiled['nodes'][node['id']]['anchor_participant'], 'actor_b')

    def test_missing_binding_and_transition_rejected(self):
        node = self.packs[0]['nodes'][0]
        node['anchor_participant'] = 'missing'
        with self.assertRaises(ValueError): compile_packs(self.packs)

    def test_gaze_targets_for_all_authored_scenes(self):
        nodes = compile_packs(self.packs)['nodes']
        for name, node in nodes.items():
            if '_test_' in name: continue
            self.assertEqual(set(node['gaze']), {'male', 'female'})
            if name == 'hzoi.standing_rear':
                self.assertEqual(node['gaze']['male'], {'participant': 'female', 'component': 'body', 'bones': ['pelvis']})
                self.assertEqual(node['gaze']['female'], {'participant': 'female', 'component': 'body', 'bones': ['upperarm_l']})
            else:
                for role, other in [('male', 'female'), ('female', 'male')]:
                    self.assertEqual(node['gaze'][role], {'participant': other, 'component': 'head',
                                                       'bones': ['FACIAL_L_Eye', 'FACIAL_R_Eye']})

    def test_gaze_is_optional_and_can_omit_individual_observers(self):
        node = self.packs[0]['nodes'][0]
        node.pop('gaze')
        self.assertNotIn('gaze', compile_packs(self.packs)['nodes'][node['id']])
        node['gaze'] = {}
        self.assertEqual(compile_packs(self.packs)['nodes'][node['id']]['gaze'], {})
        node['gaze'] = {'female': {'participant': 'female', 'component': 'body', 'bones': ['upperarm_l']}}
        self.assertEqual(set(compile_packs(self.packs)['nodes'][node['id']]['gaze']), {'female'})

    def test_invalid_gaze_data_rejected(self):
        cases = [
            {'participant': 'missing', 'component': 'head', 'bones': ['Head']},
            {'participant': [], 'component': 'head', 'bones': ['Head']},
            {'participant': 'female', 'component': 'other', 'bones': ['Head']},
            {'participant': 'female', 'component': 'head', 'bones': []},
            {'participant': 'female', 'component': 'head', 'bones': ['Head', 'Head']},
            {'participant': 'female', 'component': 'head', 'bones': ['bone";code']},
            {'participant': 'female', 'component': 'head', 'bones': [4]},
            {'participant': 'female', 'component': 'head', 'bones': ['Head'], 'callback': 'run'},
        ]
        for case in cases:
            packs = copy.deepcopy(self.packs)
            packs[0]['nodes'][0]['gaze'] = {'male': case}
            with self.assertRaises(ValueError): compile_packs(packs)
        self.packs[0]['nodes'][0]['gaze'] = {'unknown': cases[0]}
        with self.assertRaises(ValueError): compile_packs(self.packs)
        self.setUp()
        self.packs[0]['nodes'][0]['kind'] = 'transition'
        with self.assertRaises(ValueError): compile_packs(self.packs)

    def test_repeated_bodies_and_fixed_roster(self):
        for pack in self.packs:
            for node in pack['nodes']:
                node['participants']['extra'] = {'body': 'male'}
                node['tracks']['extra'] = node['tracks']['male']
                if 'male_anatomy' in node.get('attachments', {}):
                    spec = copy.deepcopy(node['attachments']['male_anatomy'])
                    spec['participant'] = 'extra'
                    node['attachments']['extra_attachment'] = spec
        nodes = compile_packs(self.packs)['nodes']
        node = nodes['hzoi.standing_rear']
        self.assertEqual(len(node['participants']), 3)
        self.assertEqual(node['tracks']['extra'], node['tracks']['male'])
        self.assertEqual(node['attachments']['extra_attachment']['participant'], 'extra')
        self.packs[0]['nodes'][0]['participants']['extra']['body'] = 'female'
        with self.assertRaises(ValueError): compile_packs(self.packs)

    def test_expression_contexts_and_facial_poses_are_role_owned(self):
        nodes=compile_packs(self.packs)['nodes']
        self.assertEqual(nodes['scenezoi.standing_idle']['expressions']['female']['context'],'idle')
        self.assertFalse(nodes['scenezoi.standing_idle']['expressions']['female'].get('facial_pose'))
        self.assertEqual(nodes['hzoi.standing_kneeling']['expressions']['female']['facial_pose'],'scenezoi.open_o')
        node=self.packs[0]['nodes'][0]
        for bad in [{'context':''}, {'context':'Idle','open_mouth':'yes'}, {'context':'Idle','callback':'run'}]:
            node['expressions']={'female':bad}
            with self.assertRaises(ValueError): compile_packs(self.packs)

    def test_neutral_expression_library(self):
        from expression_data import compile_expression_sets
        library=compile_expression_sets(sorted((ROOT/'packs/hzoi/expressions').glob('*.json')))
        self.assertEqual(len(library['sets']),5)
        self.assertEqual(library['defaults'],{'female':'hzoi.pleasure_face','male':'hzoi.confident'})
        self.assertEqual(library['contexts'],['idle','kiss','pleasure'])
        self.assertEqual(compile_expression_sets([])['sets'],{})
        for spec in library['sets'].values():
            self.assertEqual(len(spec['contexts']['kiss']['options']),1)

    def test_expression_definitions_reject_executable_or_invalid_data(self):
        import tempfile
        from expression_data import compile_expression_sets
        originals=sorted((ROOT/'packs/hzoi/expressions').glob('*.json'))
        for change in ['callback','negative_weight','invalid_hold','missing_context','duplicate_default']:
            with tempfile.TemporaryDirectory() as directory:
                paths=[]
                for original in originals:
                    data=json.loads(original.read_text(encoding='utf-8'))
                    if data['id']=='hzoi.downer':
                        if change=='callback': data['callback']='run'
                        elif change=='negative_weight': data['contexts']['Idle']['options'][0]['weight']=-1
                        elif change=='invalid_hold': data['contexts']['Idle']['hold']=[3,1]
                        elif change=='missing_context': data['contexts']['']=data['contexts'].pop('Kiss')
                        else: data['default']=True
                    target=Path(directory)/original.name;target.write_text(json.dumps(data));paths.append(target)
                with self.assertRaises(ValueError): compile_expression_sets(paths)

    def test_failed_expression_build_preserves_all_generated_outputs(self):
        import tempfile
        from build_catalog import build
        with tempfile.TemporaryDirectory() as directory:
            project=Path(directory)
            targets=[project/f'workspace/lua/{env}/SceneZOI/{file}.lua'
                     for env in ['B1','B2'] for file in ['GeneratedCatalog']]
            targets += [project/'ui/scenezoi/catalog.js']
            for target in targets:
                target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(b'previous valid build')
            invalid=project/'invalid.json';invalid.write_text('{"schema_version":999}')
            with self.assertRaises(ValueError):build([FRAMEWORK/'packs/scenezoi.json'],project,[invalid])
            self.assertTrue(all(p.read_bytes()==b'previous valid build' for p in targets),
                            'An invalid library partially overwrote a previously valid catalog')


    def test_expression_open_names_and_merging(self):
        import tempfile
        from expression_data import compile_expression_sets
        node=self.packs[0]['nodes'][0]
        node['expressions']={'female':{'context':' ToNgUe OuT '}}
        before=copy.deepcopy(self.packs)
        self.assertEqual(compile_packs(self.packs)['nodes'][node['id']]['expressions']['female']['context'],'tongue out')
        self.assertEqual(before,self.packs)
        with tempfile.TemporaryDirectory() as directory:
            first={'schema_version':2,'id':'Designer Set','body':'female','label':'Custom',
                   'aliases':['OLD.SET'],'contexts':{'Idle':{'hold':[2,7],'options':[{'animation':'/Test/A.A'}]}}}
            second={'schema_version':2,'id':'DESIGNER SET','body':'female',
                    'contexts':{'IDLE':{'options':[{'animation':'/Test/B.B'}]},'Tongue Out':{'options':[{'animation':'/Test/C.C'}]}}}
            paths=[Path(directory)/n for n in ['a.json','b.json']]
            for p,d in zip(paths,[first,second]):p.write_text(json.dumps(d))
            data=compile_expression_sets(paths)
            self.assertEqual(data['defaults'],{'female':'designer set'})
            self.assertEqual(data['aliases'],{'old.set':'designer set'})
            self.assertEqual(len(data['sets']['designer set']['contexts']['idle']['options']),2)
            self.assertEqual(data['sets']['designer set']['contexts']['idle']['hold'],[2,7])
            self.assertIn('tongue out',data['sets']['designer set']['contexts'])
            second['contexts']['IDLE']['hold']=[1,3];paths[1].write_text(json.dumps(second))
            with self.assertRaises(ValueError):compile_expression_sets(paths)

    def test_expression_file_list_is_not_executable_or_outside_pack(self):
        import tempfile
        from build_catalog import build
        for value in ['not-an-array',[123],None]:
            self.packs[0]['expression_files']=value
            with self.assertRaises(ValueError):compile_packs(self.packs)
        with tempfile.TemporaryDirectory() as directory:
            p=Path(directory)/'pack.json'
            pack={'schema_version':3,'id':'test','nodes':[],'extensions':[],'expression_files':['../outside.json']}
            p.write_text(json.dumps(pack))
            with self.assertRaises(ValueError):build([p],Path(directory))

    def test_independent_content_build_without_framework_sources(self):
        import tempfile
        from build_catalog import build
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);content=root/'HZoi'
            (content/'Meta').mkdir(parents=True)
            (content/'Meta/HZoi.mod').write_text(json.dumps({'LastModified':'20261026.16562.W.MODKIT.EGS'}))
            missing_framework=root/'framework-not-present'
            build([ROOT/'packs/hzoi.json'],missing_framework,expression_project=content)
            self.assertFalse(missing_framework.exists())
            records=json.loads((content/'workspace/data_files.json').read_text(encoding='utf-8'))['records']
            self.assertEqual(len(records),34)
            self.assertEqual({row['owner']for row in records},{'hzoi'})
            self.assertEqual({row['kind']for row in records},{'expression_set','scene_pack','body_profile','material_profile','coverage_attachment','voice_archetype','voice_context','voice_set','scene_task','localization'})

    def test_shared_declarations_are_separate_and_owned(self):
        import tempfile,hashlib
        from build_catalog import build
        with tempfile.TemporaryDirectory() as directory:
            project=Path(directory)
            (project/'workspace').mkdir();(project/'workspace/native_version.json').write_text(json.dumps({'version':'20261026.16562.W.MODKIT.EGS'}))
            for env in ['B1','B2']:(project/f'workspace/lua/{env}/SceneZOI').mkdir(parents=True)
            (project/'ui/scenezoi').mkdir(parents=True)
            packs=[FRAMEWORK/'packs/scenezoi.json',ROOT/'packs/hzoi.json']
            content=project/'separate_hzoi_project'
            (content/'Meta').mkdir(parents=True)
            (content/'Meta/HZoi.mod').write_text(json.dumps({'LastModified':'20261026.16562.W.MODKIT.EGS'}))
            build(packs,project,expression_project=content)
            inventory=json.loads((content/'workspace/data_files.json').read_text(encoding='utf-8'))
            self.assertEqual(len(inventory['files']),1)
            self.assertEqual(len(inventory['records']),34)
            self.assertEqual(len(json.loads((project/'workspace/data_files.json').read_text(encoding='utf-8'))['records']),10)
            for entry in inventory['files']:
                raw=(content/entry['path']).read_bytes();patch=json.loads(raw)
                self.assertEqual(entry['sha256'],hashlib.sha256(raw).hexdigest())
                self.assertEqual(patch['Struct'],'Text')
                for item in patch['PatchList']:
                    self.assertEqual(item['Method'],'Append')
                    self.assertEqual(item['Query'],'Text_UI')
                    envelope=json.loads(item['Value']['Text'])
                    self.assertEqual(envelope['owner'],'hzoi')
                    self.assertIn(envelope['kind'],['expression_set','scene_pack','body_profile','material_profile','coverage_attachment','voice_archetype','voice_context','voice_set','scene_task','localization'])
            other=project/'scenezoi_data/another_author.cfg';other.parent.mkdir(exist_ok=True);other.write_text('preserve another author')
            content_before=(content/'Content/JsonPatch/Text_UI_patch.json').read_bytes()
            build([FRAMEWORK/'packs/scenezoi.json'],project,expression_project=content)
            self.assertEqual((content/'Content/JsonPatch/Text_UI_patch.json').read_bytes(),content_before)
            empty_pack=project/'hzoi.json'
            pack=load_pack(ROOT/'packs/hzoi.json');pack['expression_files']=[];pack['data_files']=[];pack['nodes']=[];pack['extensions']=[];pack['sound_sets']={}
            empty_pack.write_text(json.dumps(pack))
            build([FRAMEWORK/'packs/scenezoi.json',empty_pack],project,expression_project=content)
            self.assertEqual(len(json.loads((content/'workspace/data_files.json').read_text(encoding='utf-8'))['records']),1)
            self.assertEqual(other.read_text(encoding='utf-8'),'preserve another author')
            with self.assertRaises(ValueError):build(packs,project,expression_project=project)

    def test_sound_declarations_are_multiple_role_bound_and_immutable(self):
        before=copy.deepcopy(self.packs)
        result=compile_packs(self.packs)
        hub=result['nodes']['scenezoi.standing_idle']
        self.assertFalse(hub.get('sfx'))
        self.assertTrue(all(x['context']=='idle'for x in hub['expressions'].values()))
        self.assertNotIn('sfx_extensions',next(p for p in self.packs if p['id']=='hzoi'))
        hzoi=next(p for p in self.packs if p['id']=='hzoi')
        node=hzoi['nodes'][1]
        node['participants']['helper']={'body':'female'}
        node['tracks']['helper']=node['tracks']['female']
        # Test this node independently, with two female owners and arbitrary roles.
        node['navigation']=[]
        node['attachments']={}
        node['sfx']['second']=copy.deepcopy(node['sfx']['contact'])
        node['sfx']['second']['owner']='helper'
        node['sfx']['second']['source'][0]['participant']='helper'
        node['sfx']['second']['distance']['from']['participant']='helper'
        # Keep continuous/multiple-emitter coverage without a shipped hub test.
        node['sfx']['ambience']={'mode':'continuous','owner':'helper','sound_set':'hzoi.kiss',
                                 'source':[{'participant':'helper','component':'head','bones':['FACIAL_C_LipUpper']}]}
        testpack=dict(hzoi,nodes=[node],extensions=[],attachment_extensions=[])
        compiled=compile_packs([testpack])
        self.assertEqual(len(compiled['nodes'][node['id']]['sfx']),3)
        self.assertEqual(compiled['nodes'][node['id']]['sfx']['second']['owner'],'helper')
        self.assertEqual(before[1],self.packs[1])
        self.assertEqual([v['scene_speed']for v in result['sound_sets']['hzoi.kutyu']['variants']],[.5,1,1.5,2])

    def test_invalid_sound_declarations_and_libraries_rejected(self):
        from sound_data import emitter,sound_sets
        original=compile_packs(self.packs)['nodes']['hzoi.standing_hand_job']['sfx']['contact']
        roles={'male':{'body':'male'},'female':{'body':'female'}}
        bad=[{'mode':'event'},{'owner':'missing'},{'owner':[]},{'sound_set':'script()'},{'source':[]},
             {'volume':-1},{'gap':float('nan')},{'max_voices':True},{'avoid_repeat':'yes'},
             {'callback':'run'},{'distance':{'from':original['source'][0],'to':original['source'][1],'min_delta_cm':0}},
             {'source':[dict(original['source'][0],participant=[])]}]
        for change in bad:
            with self.subTest(change=change),self.assertRaises(ValueError):emitter(dict(original,**change),roles)
        for spec in [{}, {'default':{'clips':[]}}, {'default':{'clips':['run()']}},
                     {'variants':[{'scene_speed':1.33,'clips':['/Test/S.S']}]},
                     {'default':{'clips':['/Test/S.S'],'pitch_reference':0}},
                     {'variants':[{'scene_speed':1,'clips':['/Test/S.S']}]*2}]:
            with self.subTest(spec=spec),self.assertRaises(ValueError):sound_sets({'test.sound':spec},'test')
        packs=copy.deepcopy(self.packs)
        next(p for p in packs if p['id']=='hzoi')['sound_sets'].pop('hzoi.kutyu')
        with self.assertRaises(ValueError):compile_packs(packs)
        packs=copy.deepcopy(self.packs)
        next(p for p in packs if p['id']=='hzoi')['sfx_extensions']=[]
        with self.assertRaises(ValueError):compile_packs(packs)
        collision=[{'schema_version':3,'id':pack,'nodes':[],'extensions':[],
                    'sound_sets':{'test.child.sound':{'default':{'clips':['/Test/S.S']}}}}
                   for pack in ['test','test.child']]
        with self.assertRaises(ValueError):compile_packs(collision)

    def test_sound_library_changes_digest_without_mutating_authored_data(self):
        before=copy.deepcopy(self.packs);first=compile_packs(self.packs)
        self.assertEqual(before,self.packs)
        hzoi=next(p for p in self.packs if p['id']=='hzoi')
        hzoi['sound_sets']['hzoi.kiss']['default']['clips'].pop()
        self.assertNotEqual(first['digest'],compile_packs(self.packs)['digest'])


from scene_metadata import validate_scene

class AuthoredMetadataTests(unittest.TestCase):
 def setUp(self):
  from scene_metadata import dictionaries,builtin_documents
  self.registry=dictionaries(builtin_documents())
 def test_current_scene_contact_and_activity_annotations(self):
  h=ROOT/'packs/hzoi/scenes'
  def read(name):return validate_scene(json.loads((h/name).read_text(encoding='utf-8')),self.registry)
  def tuples(node):return {(a['type'],a['actor'],a['target'],a['performer'])for a in node['actions']}
  idle=read('01_standing_idle.json');core=json.loads((FRAMEWORK/'packs/scenezoi/scenes/standing_idle.json').read_text(encoding='utf-8'))
  for key in ['tags','participant_tags','actions']:self.assertEqual(core[key],json.loads((h/'01_standing_idle.json').read_text(encoding='utf-8'))[key])
  self.assertIn('hand_on_partner_chest',idle['participant_tags']['female'])
  for name in ['zz_bed_single_idle.json','zz_bed_queen_idle.json']:
   bed=validate_scene(json.loads((FRAMEWORK/'packs/scenezoi/scenes'/name).read_text(encoding='utf-8')),self.registry)
   self.assertEqual(bed['content_rating'],'GENERAL');self.assertNotIn('eye_contact',bed['tags'])
   self.assertIn('looking_up',bed['participant_tags']['male']);self.assertIn('looking_at_own_hand',bed['participant_tags']['female'])
   self.assertIn(('holding_waist','male','female','male'),tuples(bed))
  hand=read('02_standing_hand_job.json');self.assertIn('intimate',hand['tags']);self.assertIn('eager',hand['participant_tags']['female'])
  rear=read('04_standing_rear.json');self.assertIn('bent_over',rear['participant_tags']['female']);self.assertIn('behind_partner',rear['participant_tags']['male'])
  self.assertIn(('holding_wrist','male','female','male'),tuples(rear))
 def test_fellatio_support_is_not_a_handjob_or_hug(self):
  h=ROOT/'packs/hzoi/scenes/03_male_standing_female_kneeling_fellatio.json'
  v=validate_scene(json.loads(h.read_text(encoding='utf-8')),self.registry);self.assertEqual({a['type']for a in v['actions']},{'fellatio','holding_penis_at_base'})
  self.assertTrue(all(a['actor']=='female'and a['target']=='male'and a['performer']=='female'for a in v['actions']))
  for name in ['fellatio','spanking','gesture']:self.assertNotIn(name,self.registry['tag_names'])
  self.assertIn('fellatio',self.registry['actions']);self.assertIn('spanking',self.registry['actions'])

if __name__ == '__main__': unittest.main()
