import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:nwpu_helper/constant/constants.dart';
import 'package:nwpu_helper/pages/classroom_result.dart';
import 'package:nwpu_helper/utils/global.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QueryClassroomPage extends StatefulWidget {
  @override
  _QueryClassroomPageState createState() => _QueryClassroomPageState();
}

class _QueryClassroomPageState extends State<QueryClassroomPage> {
  final menuTitles = ['校区', '大楼', '教室类型', '周数', '日期'];

  late final Future<List<Map<String, String>>> _future;

  //states
  var menuValues = <String>['', '', '', '1', '1'];
  var selectedClassRange = RangeValues(1, 13);
  final keywordController = TextEditingController();

  Future<List<Map<String, String>>> getParams() async {
    final response =
        await dio.get('http://us.nwpu.edu.cn/eams/stdRooms.action');
    constant.semesterId = int.parse(
        RegExp(r'\d+').stringMatch(response.headers['set-cookie']![0])!);
    final list = List<Map<String, String>>.empty(growable: true);
    final document = parse(response.data.toString());
    final selectors = document.querySelectorAll('select');
    selectors.forEach((selector) {
      final map = Map<String, String>();
      selector.children.forEach((option) {
        final attributes = option.attributes;
        map[attributes['title'] ?? '...'] = attributes['value'] ?? '';
      });
      list.add(map);
    });
    list.add({
      '星期一': '1',
      '星期二': '2',
      '星期三': '3',
      '星期四': '4',
      '星期五': '5',
      '星期六': '6',
      '星期日': '7',
    });
    return list;
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    menuValues = [
      prefs.getString(Constants.CAMPUS_VALUE) ?? '',
      prefs.getString(Constants.BUILDING_VALUE) ?? '',
      prefs.getString(Constants.ROOMTYPE_VALUE) ?? '',
      prefs.getString(Constants.WEEK_VALUE) ?? '1',
      prefs.getString(Constants.DATE_VALUE) ?? '1'
    ];
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _future = getParams();
    _loadPrefs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('查询空教室'),
        ),
        body: FutureBuilder(
          future: _future,
          builder: (BuildContext context,
              AsyncSnapshot<List<Map<String, String>>> snapshot) {
            List<Widget> children = [];
            if (snapshot.hasError) {
              children.addAll([
                Text("加载失败"),
              ]);
            } else if (snapshot.hasData) {
              final maps = snapshot.data!;
              maps.asMap().forEach((index, map) {
                final list =
                    List<DropdownMenuItem<String>>.empty(growable: true);
                map.forEach((key, value) {
                  list.add(DropdownMenuItem(child: Text(key), value: value));
                });
                children.add(DropdownSelector(
                    title: menuTitles[index],
                    value: menuValues[index],
                    list: list,
                    onChanged: (newValue) {
                      setState(() {
                        menuValues[index] = newValue ?? '';
                      });
                    }));
              });
            } else {
              children.add(Center(
                  child: Container(
                      margin: EdgeInsets.all(100),
                      child: CircularProgressIndicator())));
            }
            return ListView(
              children: [
                ...children,
                _buildSlider(context),
                _buildKeywordInputField(keywordController),
                Container(
                  height: MediaQuery.of(context).size.height / 6,
                ),
                _buildButton(context)
              ],
            );
          },
        ));
  }

  Row _buildButton(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return Row(
      children: [
        Container(
          width: width / 3,
        ),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              prefs.setString(Constants.CAMPUS_VALUE, menuValues[0]);
              prefs.setString(Constants.BUILDING_VALUE, menuValues[1]);
              prefs.setString(Constants.ROOMTYPE_VALUE, menuValues[2]);
              prefs.setString(Constants.WEEK_VALUE, menuValues[3]);
              prefs.setString(Constants.DATE_VALUE, menuValues[4]);
              Navigator.push(context, MaterialPageRoute(builder: (_) {
                return ClassroomResultPage(
                  campus: menuValues[0],
                  building: menuValues[1],
                  roomType: menuValues[2],
                  week: menuValues[3],
                  date: int.parse(menuValues[4]),
                  classRange: selectedClassRange,
                  keyword: keywordController.text,
                );
              }));
            },
            child: SizedBox(
              width: width / 5,
              height: 40,
              child: Center(
                child: Text(
                  "查询",
                  style: TextStyle(fontSize: 14.0),
                ),
              ),
            ),
            style: ButtonStyle(
                shape: MaterialStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(21.11))),
                backgroundColor:
                    MaterialStateProperty.all(Theme.of(context).accentColor)),
          ),
        ),
        Container(
          width: width / 3,
        ),
      ],
    );
  }

  ListTile _buildSlider(BuildContext context) {
    List<String> map = [
      '8:30',
      '9:25',
      '10:30',
      '11:25',
      '12:20',
      '13:05',
      '14:00',
      '14:55',
      '16:00',
      '16:55',
      '19:00',
      '19:55',
      '20:40',
      '21:25'
    ];

    return ListTile(
      leading: Text('课程区间'),
      trailing: Container(
        width: MediaQuery.of(context).size.width / 6 * 4,
        child: RangeSlider(
          values: selectedClassRange,
          onChanged: (RangeValues newValue) {
            setState(() => selectedClassRange = newValue);
          },
          min: 1,
          max: 14,
          divisions: 13,
          labels: RangeLabels('${map[selectedClassRange.start.toInt() - 1]}',
              '${map[selectedClassRange.end.toInt() - 1]}'),
        ),
      ),
    );
  }

  ListTile _buildKeywordInputField(TextEditingController controller) {
    return ListTile(
      leading: Text('搜索关键字'),
      trailing: Container(
        width: MediaQuery.of(context).size.width / 6 * 4,
        child: TextField(
          controller: controller,
        ),
      ),
    );
  }
}

class DropdownSelector extends StatelessWidget {
  final String title;
  final String value;
  final void Function(String?) onChanged;
  final List<DropdownMenuItem<String>> list;

  DropdownSelector(
      {Key? key,
      required this.title,
      required this.value,
      required this.list,
      required this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton(
        value: value,
        items: list,
        onChanged: onChanged,
      ),
    );
  }
}
