import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_admin/api/personApi.dart';
import 'package:flutter_admin/components/cryButton.dart';
import 'package:flutter_admin/components/cryDialog.dart';
import 'package:flutter_admin/components/form1/cryInput.dart';
import 'package:flutter_admin/components/form1/crySelect.dart';
import 'package:flutter_admin/data/data1.dart';
import 'package:flutter_admin/models/index.dart';
import 'package:flutter_admin/models/person.dart';
import 'package:flutter_admin/models/requestBodyApi.dart';
import 'package:flutter_admin/models/responeBodyApi.dart';
import 'package:flutter_admin/utils/dictUtil.dart';

import 'personEdit.dart';

class PersonList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return Curd1State();
  }
}

class Curd1State extends State {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  int rowsPerPage = 10;
  MyDS myDS = new MyDS();
  Person formData = Person();

  reset() {
    this.formData = Person();
    formKey.currentState.reset();
    myDS.loadData(params: formData.toJson());
  }

  query() {
    formKey.currentState.save();
    myDS.loadData(params: formData.toJson());
  }

  @override
  void initState() {
    super.initState();
    myDS.loadData();
    myDS.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((c) {});
  }

  @override
  Widget build(BuildContext context) {
    var form = Form(
      key: formKey,
      child: Wrap(
        children: <Widget>[
          CryInput(
            label: '人员姓名',
            onSaved: (v) {
              formData.name = v;
            },
          ),
          CrySelect(
            label: '所属部门',
            value: formData.deptId,
            dataList: deptIdList,
            onSaved: (v) {
              formData.deptId = v;
            },
          ),
        ],
      ),
    );

    ButtonBar buttonBar = ButtonBar(
      alignment: MainAxisAlignment.start,
      children: <Widget>[
        CryButton(
          label: '查询',
          onPressed: () {
            query();
          },
        ),
        CryButton(
          label: '重置',
          onPressed: () {
            reset();
          },
        ),
        CryButton(
          label: '增加',
          onPressed: () {
            cryDialog(
              width: 900,
              context: context,
              title: '增加',
              body: EditPage(),
            ).then((v) {
              if (v != null) {
                query();
              }
            });
          },
        ),
        CryButton(
          label: '修改',
          onPressed: myDS.selectedCount != 1
              ? null
              : () {
                  if (myDS.selectedRowCount != 1) {
                    return;
                  }
                  Person person = myDS.dataList.firstWhere((v) {
                    return v.selected;
                  });
                  cryDialog(
                    width: 900,
                    context: context,
                    title: '修改',
                    body: EditPage(id: person.id),
                  ).then((v) {
                    if (v) {
                      query();
                    }
                  });
                },
        ),
        CryButton(
          label: '删除',
          onPressed: myDS.selectedCount < 1
              ? null
              : () {
                  cryConfirm(context, '确定删除', () async {
                    List ids = myDS.dataList.where((v) {
                      return v.selected;
                    }).map<String>((v) {
                      return v.id;
                    }).toList();
                    await PersonApi.removeByIds(ids);
                    query();
                    Navigator.of(context).pop();
                  });
                },
        ),
      ],
    );

    Scrollbar table = Scrollbar(
      child: ListView(
        padding: const EdgeInsets.all(10.0),
        children: <Widget>[
          PaginatedDataTable(
            header: const Text('用户列表'),
            rowsPerPage: rowsPerPage,
            onRowsPerPageChanged: (int value) {
              setState(() {
                rowsPerPage = value;
              });
            },
            availableRowsPerPage: <int>[2, 5, 10, 20],
            onPageChanged: myDS.onPageChanged,
            columns: <DataColumn>[
              DataColumn(
                label: const Text('姓名'),
                onSort: (int columnIndex, bool ascending) => myDS.sort('name', ascending),
              ),
              DataColumn(label: const Text('呢称')),
              DataColumn(label: const Text('性别')),
              DataColumn(label: const Text('出生年月')),
              DataColumn(label: const Text('部门')),
              DataColumn(label: const Text('创建时间')),
              DataColumn(label: const Text('修改时间')),
            ],
            source: myDS,
          ),
        ],
      ),
    );
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 10),
          form,
          buttonBar,
          Expanded(
            child: table,
          ),
        ],
      ),
    );
  }
}

class MyDS extends DataTableSource {
  MyDS();
  List<Person> dataList;
  int selectedCount = 0;
  String orderItemColumn = "update_time";
  sort(column, ascending) {
    orderItemColumn = column;
    loadData();
  }

  loadData({params}) async {
    ResponeBodyApi responeBodyApi =
        await PersonApi.page(RequestBodyApi(page: Page(orders: [OrderItem(column: orderItemColumn)]), params: params));
    dataList = responeBodyApi.data['records'].map<Person>((v) {
      Person person = Person.fromJson(v);
      person.selected = false;
      return person;
    }).toList();
    selectedCount = 0;
    notifyListeners();
  }

  onPageChanged(firstRowIndex) {
    dataList.forEach((v) {
      v.selected = false;
    });
    selectedCount = 0;
    notifyListeners();
  }

  @override
  DataRow getRow(int index) {
    Person person = dataList[index];
    return DataRow.byIndex(
      index: index,
      selected: person.selected,
      onSelectChanged: (bool value) {
        person.selected = value;
        selectedCount += value ? 1 : -1;
        notifyListeners();
      },
      cells: <DataCell>[
        DataCell(Text(person.name ?? '--')),
        DataCell(Text(person.nickName ?? '--')),
        DataCell(Text(DictUtil.getDictName(person.gender, genderList))),
        DataCell(Text(person.birthday ?? '--')),
        DataCell(Text(DictUtil.getDictName(person.deptId, deptIdList, defaultValue: '--'))),
        DataCell(Text(person.createTime ?? '--')),
        DataCell(Text(person.updateTime ?? '--')),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => dataList == null ? 0 : dataList.length;

  @override
  int get selectedRowCount => selectedCount;
}
