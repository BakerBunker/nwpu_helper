import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:nwpu_helper/constant/constants.dart';
import 'package:nwpu_helper/utils/global.dart';

class Classroom {
  String name;
  String value;
  String type;
  String capacity;

  Classroom(this.name, this.value, this.type, this.capacity);

  @override
  String toString() {
    return '$name+$value+$type+$capacity';
  }
}

class ClassroomResultPage extends StatefulWidget {
  final String campus;
  final String building;
  final String roomType;
  final String week;
  final int date;
  final RangeValues classRange;

  ClassroomResultPage(
      {required this.campus,
      required this.building,
      required this.roomType,
      required this.week,
      required this.date,
      required this.classRange});

  @override
  _ClassroomResultPageState createState() => _ClassroomResultPageState();
}

class _ClassroomResultPageState extends State<ClassroomResultPage> {
  late final Future<List<Classroom>> _futureRooms;

  Future<List<Classroom>> getAvailableRooms() async {
    final list = List<Classroom>.empty(growable: true);
    final regex = RegExp(r'\d+');
    final result = await dio.get(
        'http://us.nwpu.edu.cn/eams/stdRooms!search.action',
        queryParameters: {
          "semesterId": constant.semesterId,
          "room.campus.id": widget.campus,
          "room.building.id": widget.building,
          "room.type.id": widget.roomType,
          "iWeek": widget.week,
          "pageNo": 1,
          "pageSize": 100
        });
    final document = parse(result.data.toString());
    final children=document.querySelector('.gridtable')!.children[1].children;
    for(var line in children){
      final children = line.children;
      final href = children[1].children[0].attributes['href'].toString();
      bool isValid=true;

      final name = children[1].text.trim();
      final value = regex.stringMatch(href) ?? '';
      final type = children[4].text;
      final capacity = children[5].text;

      await Future.delayed(Duration(milliseconds: 150));
      final roomResult=await dio.get('http://us.nwpu.edu.cn/eams/stdRooms!info.action',queryParameters: {
        'roomIds':value,
        'mode':'simple',
        'semesterId':constant.semesterId,
        'iWeek':widget.week
      });
      final roomDocument=parse(roomResult.data.toString());
      final body=roomDocument.querySelector('.gridtable')!.children[0];
      for(int i=(widget.classRange.start+1).toInt();i<(widget.classRange.end+1).toInt();i++){
        print(i);
        if(body.children[i].children[widget.date].text.contains('排课') || body.children[i].children[widget.date].text.contains('占用')){
          isValid=false;
          print('break');
          break;
        }
      }
      if(isValid) list.add(Classroom(name, value, type, capacity));
    }
    list.sort((a,b){return a.name.compareTo(b.name);});
    return list;
  }

  @override
  void initState() {
    super.initState();
    _futureRooms = getAvailableRooms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('查询结果'),
      ),
      body: FutureBuilder(
        future: _futureRooms,
        builder:
            (BuildContext context, AsyncSnapshot<List<Classroom>> snapshot) {
          List<Widget> children = [];
          if (snapshot.hasError) {
            children.addAll([Text("加载失败")]);
            print(snapshot.error.toString());
          } else if (snapshot.hasData) {
            final list = snapshot.data ?? [];
            if(list.isEmpty) return Center(child: Text('无可用教室'));
            return ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                final classroom = list[index];
                return ListTile(
                  title: Text(classroom.name),
                  trailing: Text(classroom.capacity),
                );
              },
              itemCount: list.length,
            );
          } else {
            children.add(Column(
              children: [
                Center(
                    child: Container(
                        margin: EdgeInsets.all(100),
                        child: CircularProgressIndicator())),
                Center(child: Text('由于教务系统查询频率限制，查询可能会比较慢\n并且有概率会加载失败'),)
              ],
            ));
          }
          return ListView(children: children);
        },
      ),
    );
  }
}
