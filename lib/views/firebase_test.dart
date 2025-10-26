import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:secret_sorcerer/controllers/firebase.dart';

class FirebaseTestView extends StatefulWidget {
  const FirebaseTestView({super.key});

  @override
  State<StatefulWidget> createState() {
    return _FirebaseTestViewState();
  }
}

class _FirebaseTestViewState extends State<FirebaseTestView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwardController = TextEditingController();
  final FirebaseController _firebaseController = FirebaseController();
  UserCredential? user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder()
                  ),
                  controller: _emailController,
                ),
                TextFormField(
                  controller: _passwardController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder()
                  ),
                )
              ]
            )
          ),
          ElevatedButton(onPressed: () async {
            UserCredential test = await _firebaseController.signUp(_emailController.text, _passwardController.text);
            setState(() {
              user = test;
            });
          }, child: Text("Test Firebase")),
          user != null ? Text("WORKING") : Text("NOT YET")
        ]
      )
    );
  }
}