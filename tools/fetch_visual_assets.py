"""Download the explicitly listed CC0 Poly Haven assets. No runtime network calls."""
import json, subprocess, pathlib, hashlib
ROOT=pathlib.Path(__file__).resolve().parents[1]/'assets'
HEADERS={'User-Agent':'DEADSHIFT-local-development/0.2 (asset acquisition)'}
manifest=[]
def get(url):
    return subprocess.check_output(['curl','--silent','--show-error','--fail','--location','--retry','2','--max-time','90','-A',HEADERS['User-Agent'],url])
def save(info,path):
    path.parent.mkdir(parents=True,exist_ok=True)
    if not path.exists():path.write_bytes(get(info['url']))
    if 'md5' in info and hashlib.md5(path.read_bytes()).hexdigest()!=info['md5']:raise RuntimeError('Checksum: '+str(path))
def files(asset):return json.loads(get('https://api.polyhaven.com/files/'+asset))
for asset in ['asphalt_02','brick_wall_04','concrete_wall_006','rusty_metal_02']:
    data=files(asset)
    folder=ROOT/'materials'/asset
    for key in ['diff','nor_gl','rough']:
        actual=next((k for k in data if k.lower()==key),None)
        if actual is None:actual=next((k for k in data if key=='diff' and k.lower()=='diffuse'),None)
        if actual is None:continue
        options=data[actual]['2k'];fmt='jpg' if 'jpg' in options else 'png'
        save(options[fmt],folder/(key+'.'+fmt))
    manifest.append({'asset':asset,'source':'https://polyhaven.com/a/'+asset,'license':'CC0','resolution':'2k'})
    print('Material:',asset,flush=True)
for asset in ['concrete_road_barrier','fire_hydrant','trashbag','metal_trash_can','street_lamp_01','modular_urban_apartments_facade','modular_fire_escape','rollershutter_door']:
    info=files(asset)['gltf']['1k']['gltf'];folder=ROOT/'models'/asset
    save(info,folder/(asset+'.gltf'))
    for name,item in info.get('include',{}).items():save(item,folder/name)
    manifest.append({'asset':asset,'source':'https://polyhaven.com/a/'+asset,'license':'CC0','resolution':'1k'})
    print('Model:',asset,flush=True)
(ROOT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
