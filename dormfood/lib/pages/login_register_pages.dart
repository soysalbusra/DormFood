import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dormfood/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dormfood/pages/main_screen.dart';

class LoginRegisterPages extends StatefulWidget {
  const LoginRegisterPages({ super.key });

  @override
  State<LoginRegisterPages> createState() => _LoginRegisterPagesState();
}

class _LoginRegisterPagesState extends State<LoginRegisterPages> {

  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  bool isLogin = true;
  String? errorMessage;

  Future<void> createUser() async {
    try {
      await Auth().createUser(
        email: emailController.text, password: passwordController.text);
      String uid = FirebaseAuth.instance.currentUser!.uid;
      print("uid: $uid");

      await FirebaseFirestore.instance.collection('Users').doc(uid)
        .set({
          'email': emailController.text,
          'name': nameController.text,
          'surname': surnameController.text,
        })
        .then((value) => print("User added."))
        .catchError((error) => print("An error occurred: $error"));

      // Kayıt olduktan sonra login sayfasına yönlendir
      setState(() {
        isLogin = true;
      });

    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Future<void> signIn() async {
    try {
      await Auth().signIn(email: emailController.text, password: passwordController.text);

      String uid = FirebaseAuth.instance.currentUser!.uid;
      print("uid: $uid");

      // Firestore'dan kullanıcı bilgilerini kontrol et
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
      if (userDoc.exists) {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MainScreen()));
      } else {
        setState(() {
          errorMessage = "User not found in database.";
        });
        await FirebaseAuth.instance.signOut();
      }

    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          
            const SizedBox(height: 20),
            if (!isLogin) ...[
              const Text(
                "Register",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                "Name",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: "Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Surname",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: surnameController,
                decoration: const InputDecoration(
                  hintText: "Surname",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Email",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  hintText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Password",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              errorMessage != null ? Text(errorMessage!, style: TextStyle(color: Colors.red)) : const SizedBox.shrink(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: createUser,
                child: const Text("Register"),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  setState(() {
                    isLogin = true;
                  });
                },
                child: const Text("If you have an account yet, Click here"),
              ),
            ] else ...[
           
          SvgPicture.asset( 'assets/image_1.svg', // Assuming the image is saved in the assets folder
           width: 150, // Set the desired width
            height: 150,),
            const SizedBox(height: 20),


              const Text(
                "Login",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                "Email",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  hintText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Password",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              errorMessage != null ? Text(errorMessage!, style: TextStyle(color: Colors.red)) : const SizedBox.shrink(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: signIn,
                child: const Text("Login"),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  setState(() {
                    isLogin = false;
                  });
                },
                child: const Text("If you don't have an account yet, Click Here"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
