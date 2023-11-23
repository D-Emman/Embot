import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResponseListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Response List"),
      ),
      body: ResponseListView(),
    );
  }
}

class ResponseListView extends StatefulWidget {
  @override
  _ResponseListViewState createState() => _ResponseListViewState();
}

class _ResponseListViewState extends State<ResponseListView> {
  List<String> responses = [];

  @override
  void initState() {
    super.initState();
    _loadResponses();
  }

  Future<void> _loadResponses() async {
    final prefs = await SharedPreferences.getInstance();
    final storedResponses = prefs.getStringList('responses');
    if (storedResponses != null) {
      setState(() {
        responses = storedResponses;
      });
    }
  }


  Future<void> _deleteResponse(int index) async {
    setState(() {
      responses.removeAt(index);
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('responses', responses);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: responses.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text("Response ${index + 1}"),
          subtitle: Text(responses[index]),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Delete Response"),
                  content: Text("Are you sure you want to delete this response?"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                      child: Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        _deleteResponse(index);
                        Navigator.of(context).pop(); // Close the dialog
                      },
                      child: Text("Delete"),
                    ),
                  ],
                ),
              );
            },
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExpandedResponsePage(response: responses[index]),
              ),
            );
          },
        );
      },
    );
  }
}

class ExpandedResponsePage extends StatelessWidget {
  final String response;

  ExpandedResponsePage({required this.response});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Expanded Response"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(response),
      ),
    );
  }
}
