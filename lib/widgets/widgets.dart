import 'package:flutter/material.dart';

const textInputDecoration = InputDecoration(
  labelStyle: TextStyle(color: Colors.black),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Color(0xFF008080), width: 2), // Teal
  ),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Color(0xFF20B2AA), width: 2), // Light Teal
  ),
  errorBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Color(0xFF005F5F), width: 2), // Dark Teal
  ),
);


void nextScreen(context, page) {
  Navigator.push(context, MaterialPageRoute(builder: (context) => page));
}

void nextScreenReplaced(context, page) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => page),
  );
}

void showSnackbar(context, color, message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: TextStyle(fontSize: 14)),
      backgroundColor: color,
      duration: Duration(seconds: 1),
      action: SnackBarAction(label: "Ok", onPressed: (){}, textColor: Colors.white,),
    ),
  );
}
