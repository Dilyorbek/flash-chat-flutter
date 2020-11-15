import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';

final _fireStore = FirebaseFirestore.instance;
User user;

class ChatScreen extends StatefulWidget {
  static const String id = "chat_screen";

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  String _message;
  final _messageTextController = TextEditingController();

  void getCurrentUser() {
    try {
      final tempUser = _auth.currentUser;
      if (tempUser != null) {
        user = tempUser;
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () async {
                await _auth.signOut();
                Navigator.pop(context);
                // streamMessages();
              }),
        ],
        title: Center(child: Text('⚡️Chat')),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _messageTextController,
                      onChanged: (value) {
                        _message = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () async {
                      _messageTextController.clear();
                      await _fireStore.collection("messages").add({
                        "text": _message,
                        "sender": user.email,
                        "timestamp": Timestamp.now(),
                      });
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// void getMessages() async {
//   final messages = await _fireStore.collection("messages").get();
//   for(var message in messages.docs) {
//     print(message.data());
//   }
// }

// void streamMessages() async {
//   await for (var snapshot in _fireStore.collection("messages").snapshots()) {
//     for (var message in snapshot.docs) {
//       print(message.data());
//     }
//   }
// }
}

class MessagesStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _fireStore
          .collection("messages")
          .orderBy(
            "timestamp",
            descending: true,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlue,
            ),
          );
        }
        final messages = snapshot.data.documents; //.orderby('timestamp', descending: true);
        List<Widget> messageWidgets = [];
        for (var message in messages) {
          final sender = message['sender'];
          final text = message['text'];
          final messageWidget = MessageWidget(
            sender: sender,
            text: text,
            isMe: user.email == sender,
          );
          messageWidgets.add(messageWidget);
        }

        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: messageWidgets,
          ),
        );
      },
    );
  }
}

class MessageWidget extends StatelessWidget {
  final String sender;
  final String text;
  final bool isMe;

  const MessageWidget({Key key, this.sender, this.text, this.isMe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: TextStyle(
              fontSize: 12.0,
              color: Colors.black54,
            ),
          ),
          Material(
            elevation: 5.0,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: isMe ? Radius.circular(30.0) : Radius.zero,
              bottomLeft: Radius.circular(30.0),
              bottomRight: Radius.circular(30.0),
              topRight: isMe ? Radius.zero : Radius.circular(30.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black54,
                  fontSize: 15.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
