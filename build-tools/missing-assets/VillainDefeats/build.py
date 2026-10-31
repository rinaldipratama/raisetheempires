"""Build stand-ins for the lost villain defeat SWFs (needs Haxe 4.x).

Run from this directory: python build.py

For each missing defeat clip this generates a tiny root class that calls PUVillainDefeat.draw with
the villain's portrait (the `portrait` image of that villain in gameSettings.xml), compiles it with
Haxe, and makes that class the SWF's root (document) class, so the clip draws itself as soon as the
game instantiates it instead of waiting for Haxe's boot class to be added to the stage.
"""
import pathlib
import struct
import subprocess
import tempfile
import zlib

HERE = pathlib.Path(__file__).resolve().parent
ASSETS = HERE.parents[2] / 'assets' / 'sol_assets_octdict'

V1 = 'assets/game/villains/Villains01.swf/'
V2 = 'assets/game/villains/Campaign02_Villains.swf/'

# defeat clip referenced by gameSettings.xml -> that villain's portrait image
STAND_INS = {
    'assets/game/villains/defeats/VBossCPD_01A.swf': V1 + 'VP_01.png',
    'assets/game/villains/defeats/VBossCPD_02A.swf': V1 + 'VP_02.png',
    'assets/game/villains/defeats/VBossCPD_04A.swf': V1 + 'VP_04.png',
    'assets/game/villains/defeats/VBossCPD_06A.swf': V1 + 'VP_06.png',
    'assets/game/villains/defeats/VBossCPD_09A.swf': V1 + 'VP_09.png',
    'assets/game/villains/defeats/VBossCPD_12A.swf': V1 + 'VP_12.png',
    'assets/game/villains/defeats/VBossCPD_13A.swf': V1 + 'VP_13.png',
    'assets/game/villains/Campaign02_Defeats/AbandonedSoldier_Defeat.swf': V2 + 'AbandonedSoldierPolaroid_124.png',
    'assets/game/villains/Campaign02_Defeats/FlameThrowerChick_Defeat.swf': V2 + 'FlameThrowerChickPolaroid_124.png',
    'assets/game/villains/Campaign02_Defeats/NativeTikiGuy_Defeat.swf': V2 + 'NativeTikiGuyPolaroid_124.png',
    'assets/game/villains/Campaign02_Defeats/VooDooDoctor_Defeat.swf': V2 + 'VooDooDoctorPolaroid_124.png',
    'assets/game/villains/Campaign02_Defeats/ZombieSoldier_Defeat.swf': V2 + 'ZombiePolaroid_124.png',
}

ROOT_CLASS = '''@:keep
class {name} extends flash.display.MovieClip {{
	public function new() {{
		super();
		PUVillainDefeat.draw(this, "{portrait}");
	}}

	static function main() {{}}
}}
'''


def read_tags(body, offset):
    while offset < len(body):
        code_and_length = struct.unpack_from('<H', body, offset)[0]
        code, length, header = code_and_length >> 6, code_and_length & 0x3F, 2
        if length == 0x3F:
            length, header = struct.unpack_from('<I', body, offset + 2)[0], 6
        yield code, offset, header + length
        offset += header + length


def set_root_class(swf, class_name):
    """Point SymbolClass entry 0 (the root clip) at class_name."""
    assert swf[:3] == b'CWS'
    body = zlib.decompress(swf[8:])
    rect_bits = 5 + 4 * (body[0] >> 3)
    first_tag = (rect_bits + 7) // 8 + 4  # RECT, frame rate, frame count
    for code, offset, size in read_tags(body, first_tag):
        if code == 76:  # SymbolClass
            data = struct.pack('<HH', 1, 0) + class_name.encode() + b'\0'
            tag = struct.pack('<HI', (76 << 6) | 0x3F, len(data)) + data
            body = body[:offset] + tag + body[offset + size:]
            return b'CWS' + swf[3:4] + struct.pack('<I', 8 + len(body)) + zlib.compress(body)
    raise ValueError('no SymbolClass tag')


def build(path, portrait):
    name = 'PUVillainDefeat_' + pathlib.Path(path).stem
    with tempfile.TemporaryDirectory() as tmp:
        (pathlib.Path(tmp) / (name + '.hx')).write_text(ROOT_CLASS.format(name=name, portrait=portrait))
        out = pathlib.Path(tmp) / 'out.swf'
        subprocess.run(['haxe', '-cp', str(HERE / 'src'), '-cp', tmp, '-main', name, '-swf', str(out),
                        '-swf-version', '10', '-D', 'swf-header=760:600:30:FFFFFF'], check=True)
        target = ASSETS / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(set_root_class(out.read_bytes(), name))
    print('built', target.relative_to(HERE.parents[2]))


if __name__ == '__main__':
    for path, portrait in STAND_INS.items():
        build(path, portrait)
