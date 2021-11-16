import 'package:flutter/material.dart';
import 'package:ncmb/ncmb.dart';

void main() {
  // NCMBを初期化
  NCMB('cfbfa63791b4fa2d3d81dfaa4af96c0b696d9d4c4de16285fb54b640db6f140a',
      '24178b22dce79ac65631163fff1d515b2de00fdd4a1a3f375e443f047a97fb34');
  // 最初に表示するWidget
  runApp(MyTodoApp());
}

class MyTodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 右上に表示される"debug"ラベルを消す
      debugShowCheckedModeBanner: false,
      // アプリ名
      title: 'タスクアプリ',
      theme: ThemeData(
        // テーマカラー
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // リスト一覧画面を表示
      home: TodoListPage(),
    );
  }
}

// タスク一覧画面用Widget
class TodoListPage extends StatefulWidget {
  @override
  _TodoListPageState createState() => _TodoListPageState();
}

// タスク一覧画面用ステート
class _TodoListPageState extends State<TodoListPage> {
  // Todoリストのデータ（初期値は空）
  List<NCMBObject> todoList = [];

  // 初期データをセットアップする処理
  @override
  void initState() {
    super.initState();
    getAllTask();
  }

  // NCMBから既存のTodoリストを取得する処理
  void getAllTask() async {
    // Todoクラス（DBで言うテーブル相当）を検索するクエリーオブジェクト
    var query = NCMBQuery('Todo');
    // データを取得
    var items = await query.fetchAll();
    // データを適用
    setState(() {
      todoList = items;
    });
  }

  // 画面構築
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 画面上部に表示するAppBar
      appBar: AppBar(
        title: Text('タスク一覧'),
        // タスク追加用のアイコンを設置
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              // 新しいTodoを取得
              final NCMBObject item = await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) {
                  // タスクの追加、編集を行う画面への遷移
                  return TodoPage(
                    // 初期値としてNCMBObjectを渡す
                    todo: NCMBObject('Todo'),
                  );
                }),
              );
              // レスポンスがあれば、リストに追加
              // キャンセルされた場合は null が来る
              if (item != null) {
                setState(() {
                  todoList.add(item);
                });
              }
            },
          ),
        ],
      ),
      // データを元にListViewを作成
      body: ListView.builder(
        itemCount: todoList.length,
        itemBuilder: (context, index) {
          final item = todoList[index];
          // スワイプで削除する機能
          return Dismissible(
            key: Key(item.get('objectId') as String),
            child: Card(
              child: ListTile(
                title: Text(item.get('body') as String),
                onTap: () async {
                  // タップした際には編集画面に遷移する
                  final NCMBObject obj = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) {
                      return TodoPage(
                        todo: item,
                      );
                    }),
                  );
                  // 編集後のデータがあれば、リストを更新する
                  if (obj != null) {
                    setState(() {
                      todoList[index] = obj;
                    });
                  }
                },
              ),
            ),
            direction: DismissDirection.endToStart,
            // スワイプした際に表示する削除ラベル
            background: new Container(
                padding: EdgeInsets.only(right: 20.0),
                color: Colors.red,
                child: new Align(
                  alignment: Alignment.centerRight,
                  child: new Text('削除',
                      textAlign: TextAlign.right,
                      style: new TextStyle(color: Colors.white)),
                )),
            // スワイプした際に処理
            onDismissed: (direction) {
              // スワイプされた要素をデータから削除する
              setState(() {
                todoList[index].delete();
                todoList.removeAt(index);
              });
              // Snackbarを表示する
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('削除しました')));
            },
          );
        },
      ),
    );
  }
}

// Todoを受け取るステートフルウィジェット
class TodoPage extends StatefulWidget {
  TodoPage({
    Key key,
    this.todo,
  }) : super(key: key);

  final NCMBObject todo;

  @override
  _TodoPageState createState() => _TodoPageState();
}

// Todoの追加、または更新を行うウィジェット
class _TodoPageState extends State<TodoPage> {
  // テキスト入力用
  String _text;
  @override
  Widget build(BuildContext context) {
    // 画面表示用のラベル
    final label = widget.todo.get('objectId') != null ? 'リスト更新' : 'リスト追加';
    return Scaffold(
      // 画面上部に表示するAppBar
      appBar: AppBar(
        title: Text(label),
        actions: <Widget>[
          // 新規保存、更新用のボタン
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () async {
              // 保存処理
              widget.todo.set('body', _text);
              await widget.todo.save();
              // 前の画面に戻る
              Navigator.of(context).pop(widget.todo);
            },
          ),
        ],
      ),
      body: Container(
        // 余白を付ける
        padding: EdgeInsets.all(64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 8),
            // テキスト入力
            TextFormField(
              initialValue: (_text = widget.todo.get('body') as String),
              onChanged: (String value) {
                _text = value;
              },
            ),
          ],
        ),
      ),
    );
  }
}
