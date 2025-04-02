import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:groupie_v2/core/shared/constants.dart';
import 'package:groupie_v2/core/shared/textstyles.dart';
import 'package:groupie_v2/data/sources/helper_function.dart';
import '../../widgets/widgets.dart';
import '../search/bloc/search_bloc.dart';
import '../search/bloc/search_event.dart';
import '../search/bloc/search_state.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController searchController = TextEditingController();
  late String userName;
  late User user;

  @override
  void initState() {
    super.initState();
    getCurrentUserDetails();
  }

  Future<void> getCurrentUserDetails() async {
    userName = (await HelperFunctions.getUserNameSF()) ?? "";
    user = FirebaseAuth.instance.currentUser!;
  }

  void onSearch() {
    if (searchController.text.isNotEmpty) {
      context.read<SearchBloc>().add(SearchGroups(searchController.text));
    }
  }

  void onJoinRequest(String groupId, String groupName) {
    context.read<SearchBloc>().add(SendJoinRequest(
      groupId: groupId,
      groupName: groupName,
      userName: userName,
      userId: user.uid,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants().backGroundColor,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          "S E A R C H",
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          const Divider(height: 2, thickness: 1, color: Colors.white),
          Container(
            color: Theme.of(context).primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search for a group...",
                      hintStyle: AppTextStyles.small,
                      border: const OutlineInputBorder(),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onSearch,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.search_outlined, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<SearchBloc, SearchState>(
              listener: (context, state) {
                if (state is JoinRequestSent) {
                  showSnackbar(context, Constants().primaryColor,
                      "Sent a request to ${state.groupName}");
                } else if (state is SearchError) {
                  showSnackbar(context, Colors.red, state.message);
                }
              },
              builder: (context, state) {
                if (state is SearchLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is SearchLoaded) {
                  return ListView.builder(
                    itemCount: state.results.docs.length,
                    itemBuilder: (context, index) {
                      final doc = state.results.docs[index];
                      return groupTile(
                        groupId: doc['groupId'],
                        groupName: doc['groupName'],
                        admin: doc['admin'],
                      );
                    },
                  );
                } else {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: Text(
                        "Search for groups above",
                        style: AppTextStyles.medium,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget groupTile({
    required String groupId,
    required String groupName,
    required String admin,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      title: Text(groupName, style: AppTextStyles.medium),
      leading: CircleAvatar(
        radius: 30,
        backgroundColor: Theme.of(context).primaryColor,
        child: Text(
          groupName.substring(0, 1).toUpperCase(),
          style: AppTextStyles.medium,
        ),
      ),
      trailing: InkWell(
        onTap: () => onJoinRequest(groupId, groupName),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).primaryColor,
          ),
          child: const Text(
            "Request Join?",
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
