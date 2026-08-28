import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:plastica_suc/view/constants/drawer.dart';

class Menbre extends StatefulWidget {
  const Menbre({super.key});

  @override
  State<Menbre> createState() => _MenbreState();
}

class _MenbreState extends State<Menbre> {
  final CollectionReference _user = FirebaseFirestore.instance.collection(
    "users",
  );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Color(0xFFF5F7FB),
          title: Text('Employers'),
        ),
        drawer: Drawers(),

       body:  Column(
                        children: [
                          Center(child: Text('liste des employers',style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold
                          ),),),
                          SizedBox(height: 20,),
                          SizedBox(
                            height: 300,
                            child: StreamBuilder<QuerySnapshot>(
                              stream: _user.snapshots(),
                              builder: ((context, snapshot) {
                                if (snapshot.hasData) {
                                  return ListView(
                                    children: snapshot.data!.docs.map((doc) {
                                      return Card(
                                        elevation: 10,
                                        child: ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor: Colors.white,
                                              child: Icon(Icons.person),),
                                            title: Text(doc['name'],style: TextStyle(fontWeight: FontWeight.w800),),
                                            subtitle: Text(doc['role'],style: TextStyle(fontWeight: FontWeight.w500),),
                                            trailing: IconButton(onPressed: () async{
                                               await _user
                                              .doc(doc.reference.id)
                                              .delete();
                                            }, 
                                            icon: Icon(Icons.delete,color: Colors.red,)),
                                          ),
                                      );
                                     
                                    }).toList(),
                                  );
                                } else if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                    child: CircularProgressIndicator.adaptive(),
                                  );
                                } else {
                                  return Center(child: Text('pas de donnees'));
                                }
                              }),
                            ),
                          ),
                          
                        ],
                      ),
                  
    );
  }
}