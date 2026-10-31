#TO RUN TESTS RUN empires_test.py
from flask import Flask, session

import quest_engine

app = Flask(__name__)
app.secret_key = 'test'


def test_prepopulate_task_neighbors():
    with app.test_request_context():
        setup_session()

        res = quest_engine.prepopulate_task(
            {
                "cost": {
                    "_amount": "55"
                },
                "invite": {
                    "_button": "Dialogs:InviteButton"
                },
                "_action": "neighborsAdded",
                "_total": "3",
                "_desc": "quest_FD0207_task_03",
                "_icon": "assets/game/quests/Quests_Icons_0.swf/DefendVsGround01_96.png"
            })

        assert res == (3, True)


def test_prepopulate_task_neighbors_added_helping_hands():
    with app.test_request_context():
        setup_session()

        res = quest_engine.prepopulate_task(
            {'cost': {'_amount': '40'}, '_action': 'neighborsAdded', '_total': '1', '_desc': 'quest_1140_task_01',
             '_icon': 'assets/game/quests/Quests_Icons_0.swf/Visit01_96.png'})

        assert res == (0, False)


def setup_session():
    session["quests"] = [{'name': 'Q0651', 'complete': True, 'expired': False, 'progress': [1, 1], 'completedTasks': 3},
                         {'name': 'Q6019', 'complete': True, 'expired': False, 'progress': [1], 'completedTasks': 1},
                         {'name': 'Q0633', 'complete': True, 'expired': False, 'progress': [1, 2, 1],
                          'completedTasks': 7},
                         {'name': 'Q0676', 'complete': False, 'expired': False, 'progress': [0], 'completedTasks': 0},
                         {'name': 'Q0521', 'complete': False, 'expired': False, 'progress': [0], 'completedTasks': 0},
                         {'name': 'Q0691', 'complete': True, 'expired': False, 'progress': [1], 'completedTasks': 1},
                         {'name': 'Q0671', 'complete': True, 'expired': False, 'progress': [2, 2], 'completedTasks': 3},
                         {'name': 'Q0571', 'complete': True, 'expired': False, 'progress': [1, 1], 'completedTasks': 3},
                         {'name': 'Q0591', 'complete': True, 'expired': False, 'progress': [4], 'completedTasks': 1},
                         {'name': 'Q1098', 'complete': True, 'expired': False, 'progress': [1], 'completedTasks': 1},
                         {'name': 'Q6011', 'complete': True, 'expired': False, 'progress': [1], 'completedTasks': 1},
                         {'name': 'Q0611', 'complete': True, 'expired': False, 'progress': [1], 'completedTasks': 1},
                         {'name': 'Q6016', 'complete': True, 'expired': False, 'progress': [1], 'completedTasks': 1},
                         {'name': 'Q0531', 'complete': True, 'expired': False, 'progress': [1], 'completedTasks': 1},
                         {'name': 'Q0516', 'complete': True, 'expired': False, 'progress': [1], 'completedTasks': 1}]


def test_new_quest():
    with app.test_request_context():
        setup_session()

        res = quest_engine.new_quest({'sequels': '', 'tasks': {
            'task': {'cost': {'_amount': '40'}, '_action': 'neighborsAdded', '_total': '1',
                     '_desc': 'quest_1140_task_01',
                     '_icon': 'assets/game/quests/Quests_Icons_0.swf/Visit01_96.png'}},
         'reward': {'_type': 'coins', '_count': '200'}, '_name': 'Q1140', '_visible': 'true',
         '_title': 'quest_1140_title',
         '_introIcon': 'assets/game/quests/Quests_Icons_0.swf/CityOfficial01_96.png',
         '_introTooltip': 'quest_1140_introTooltip', '_introSpeech': 'Speech_Sarah_1140_01', '_desc': 'quest_1140_desc',
         '_hint': 'quest_1140_hint', '_complete': 'quest_1140_complete', '_tooltip': 'quest_1140_tooltip',
         '_advisorId': 'a02', '_buttonIcon': 'assets/game/quests/Quests_Icons_0.swf/Visit01_96.png'})

        assert res == {'name': 'Q1140', 'complete': False, 'expired': False, 'progress': [0], 'completedTasks': 0}


def test_new_quest_with_sequels():
    with app.test_request_context():
        setup_session()
        meta = {'newPVE': 0}
        new_quests = [{'name': 'Q1011', 'complete': False, 'expired': False, 'progress': [0], 'completedTasks': 0}]

        quest_engine.new_quest_with_sequels('Q1140', new_quests, meta)

        assert new_quests == [
            {'name': 'Q1011', 'complete': False, 'expired': False, 'progress': [0], 'completedTasks': 0},
            {'name': 'Q1140', 'complete': False, 'expired': False, 'progress': [0], 'completedTasks': 0}]


def test_activate_sequels():
    with app.test_request_context():
        setup_session()
        meta = {'newPVE': 0}
        new_quests = []

        quest_engine.activate_sequels({'name': 'Q0651', 'complete': True, 'expired': False, 'progress': [1, 1], 'completedTasks': 3}, new_quests, meta)

        assert new_quests == [
            {'name': 'Q1011', 'complete': False, 'expired': False, 'progress': [0], 'completedTasks': 0},
            {'name': 'Q1140', 'complete': False, 'expired': False, 'progress': [0], 'completedTasks': 0}]


def test_progress_move():
    army_unit = {'-code': 'U01', '-name': 'infantry01', '-subtype': 'army'}
    building = {'-code': 'B07', '-name': 'house01', '-subtype': 'residence'}
    move_army_task = {'_action': 'move', '_subtype': 'army', '_total': '1'}  # Q0805
    move_item_task = {'_action': 'move', '_item': 'AU06', '_total': '1'}  # QW126

    assert quest_engine.progress_move(army_unit)(move_army_task, 0, 0, {})
    assert not quest_engine.progress_move(building)(move_army_task, 0, 0, {})
    assert quest_engine.progress_move({'-code': 'AU06', '-subtype': 'army'})(move_item_task, 0, 0, {})
    assert not quest_engine.progress_move(army_unit)(move_item_task, 0, 0, {})
    assert not quest_engine.progress_move(army_unit)({'_action': 'place', '_total': '1'}, 0, 0, {})


def test_handle_quest_progress():
    with app.test_request_context():
        setup_session()
        session["quests"][0] = {'name': 'Q0651', 'complete': False, 'expired': False, 'progress': [1, 0], 'completedTasks': 1}
        meta = {'newPVE': 0}
        session['user_object'] = {}
        session['user_object']["userInfo"] = {}
        session['user_object']["userInfo"]["player"] = {"xp": 0, "energy": 0, "cash": 0, "socialXpGood": 0, "socialXpBad": 0, "level": 0, "energyMax": 0, "playerResourceType": 3, "lastEnergyCheck": 0}
        session['user_object']["userInfo"]["world"] = {}
        session['user_object']["userInfo"]["world"]["resources"] = {"coins": 0, "energy": 0, "oil": 0, "wood": 0, "aluminum": 0, "copper": 0, "gold": 0, "iron": 0, "uranium": 0}
        session['user_object']["userInfo"]["world"]["resourceOrder"] = ["aluminum", "copper", "gold", "iron", "uranium"]
        session['user_object']["experiments"] = {}

        quest_engine.handle_quest_progress(meta, (lambda task, *args: task["_action"] == "tending"))

        assert meta == {'newPVE': 0, 'QuestComponent': [
            {'name': 'Q0651', 'complete': True, 'expired': False, 'progress': [1, 1], 'completedTasks': 3},
            {'name': 'Q1011', 'complete': False, 'expired': False, 'progress': [0], 'completedTasks': 0},
            {'name': 'Q1140', 'complete': False, 'expired': False, 'progress': [0], 'completedTasks': 0}]}
        assert session["quests"] == [{'name': 'Q1011', 'complete': False, 'expired': False, 'progress': [0], 'completedTasks': 0},
                           {'name': 'Q1140', 'complete': False, 'expired': False, 'progress': [0], 'completedTasks': 0},
                           {'name': 'Q0651', 'complete': True, 'expired': False, 'progress': [1, 1],
                            'completedTasks': 3},
                           {'name': 'Q6019', 'complete': True, 'expired': False, 'progress': [1], 'completedTasks': 1},
                           {'name': 'Q0633', 'complete': True, 'expired': False, 'progress': [1, 2, 1],
                            'completedTasks': 7},
                           {'name': 'Q0676', 'complete': False, 'expired': False, 'progress': [0], 'completedTasks': 0},
                           {'name': 'Q0521', 'complete': False, 'expired': False, 'progress': [0], 'completedTasks': 0},
                           {'name': 'Q0691', 'complete': True, 'expired': False, 'progress': [1], 'completedTasks': 1},
                           {'name': 'Q0671', 'complete': True, 'expired': False, 'progress': [2, 2],
                            'completedTasks': 3},
                           {'name': 'Q0571', 'complete': True, 'expired': False, 'progress': [1, 1],
                            'completedTasks': 3},
                           {'name': 'Q0591', 'complete': True, 'expired': False, 'progress': [4], 'completedTasks': 1},
                           {'name': 'Q1098', 'complete': True, 'expired': False, 'progress': [1], 'completedTasks': 1},
                           {'name': 'Q6011', 'complete': True, 'expired': False, 'progress': [1], 'completedTasks': 1},
                           {'name': 'Q0611', 'complete': True, 'expired': False, 'progress': [1], 'completedTasks': 1},
                           {'name': 'Q6016', 'complete': True, 'expired': False, 'progress': [1], 'completedTasks': 1},
                           {'name': 'Q0531', 'complete': True, 'expired': False, 'progress': [1], 'completedTasks': 1},
                           {'name': 'Q0516', 'complete': True, 'expired': False, 'progress': [1], 'completedTasks': 1}]


def setup_level_up_session(level, xp, energy):
    session["quests"] = []
    session['user_object'] = {"experiments": {}, "userInfo": {}}
    session['user_object']["userInfo"]["player"] = {"xp": xp, "energy": energy, "cash": 0, "socialXpGood": 0, "socialXpBad": 0, "level": level, "energyMax": 0, "playerResourceType": 3, "lastEnergyCheck": 0, "inventory": {"items": {}}}
    session['user_object']["userInfo"]["world"] = {"resourceOrder": ["aluminum", "copper", "gold", "iron", "uranium"]}
    session['user_object']["userInfo"]["world"]["resources"] = {"coins": 0, "energy": energy, "oil": 0, "wood": 0, "aluminum": 0, "copper": 0, "gold": 0, "iron": 0, "uranium": 0}


def test_do_rewards_level_up_energy():
    with app.test_request_context():
        setup_level_up_session(level=9, xp=426, energy=5)
        quest_engine.do_rewards("Quest", [{"-type": "xp", "-count": "1"}], {})
        player = session['user_object']["userInfo"]["player"]
        assert (player['level'], player['energy'], player['energyMax']) == (10, 31, 31)  # refilled to the cap

        setup_level_up_session(level=9, xp=426, energy=40)
        quest_engine.do_rewards("Quest", [{"-type": "xp", "-count": "1"}], {})
        player = session['user_object']["userInfo"]["player"]
        assert (player['level'], player['energy'], player['energyMax']) == (10, 40, 31)  # overfill kept


def test_do_rewards_level_up_past_energy_cap_table():
    with app.test_request_context():
        level_67_xp = int([l for l in quest_engine.game_settings['settings']['levels']['level'] if l['-num'] == '67'][0]['-requiredXP'])
        setup_level_up_session(level=66, xp=level_67_xp - 1, energy=0)
        quest_engine.do_rewards("Quest", [{"-type": "xp", "-count": "1"}], {})
        player = session['user_object']["userInfo"]["player"]
        assert (player['level'], player['energyMax']) == (67, 46)  # energycaps ends at level 66, keep its last cap
