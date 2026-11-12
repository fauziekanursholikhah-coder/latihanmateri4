import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../models/contact.dart';
import 'contact_form_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref('contacts');

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';

  Future<void> _deleteContact(
    String id,
    String name,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Kontak'),
          content: Text(
            'Yakin ingin menghapus "$name" dari buku alamat?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Hapus',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _dbRef.child(id).remove();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '"$name" berhasil dihapus',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus: $e'),
            ),
          );
        }
      }
    }
  }

  Future<void> _openForm({
    Contact? contact,
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContactFormPage(
          contact: contact,
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            contact == null
                ? 'Kontak berhasil ditambahkan'
                : 'Kontak berhasil diperbarui',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buku Alamat'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              12,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama atau nomor...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),

      body: StreamBuilder<DatabaseEvent>(
        stream: _dbRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Terjadi kesalahan:\n${snapshot.error}',
              ),
            );
          }

          final value = snapshot.data?.snapshot.value;

          if (value == null) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.contacts_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Buku alamat masih kosong.\n'
                    'Tekan tombol + untuk menambah kontak.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final data =
              Map<dynamic, dynamic>.from(value as Map);

          final contacts = data.entries
              .map(
                (entry) => Contact.fromMap(
                  entry.key.toString(),
                  Map<dynamic, dynamic>.from(
                    entry.value as Map,
                  ),
                ),
              )
              .where((contact) {
                if (_searchQuery.isEmpty) {
                  return true;
                }

                return contact.name
                        .toLowerCase()
                        .contains(_searchQuery) ||
                    contact.phone
                        .toLowerCase()
                        .contains(_searchQuery);
              })
              .toList();

          contacts.sort(
            (a, b) => a.name
                .toLowerCase()
                .compareTo(
                  b.name.toLowerCase(),
                ),
          );

          if (contacts.isEmpty) {
            return Center(
              child: Text(
                'Tidak ada kontak yang cocok dengan '
                '"$_searchQuery"',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(
              bottom: 90,
            ),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      contact.name.isNotEmpty
                          ? contact.name[0]
                              .toUpperCase()
                          : '?',
                    ),
                  ),

                  title: Text(
                    contact.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),

                      Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(contact.phone),
                        ],
                      ),

                      const SizedBox(height: 3),

                      Row(
                        children: [
                          const Icon(
                            Icons.email,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              contact.email,
                              overflow:
                                  TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 3),

                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.home,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              contact.address,
                              maxLines: 2,
                              overflow:
                                  TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  trailing:
                      PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _openForm(
                          contact: contact,
                        );
                      } else if (value == 'delete') {
                        _deleteContact(
                          contact.id!,
                          contact.name,
                        );
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text('Hapus'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah Kontak'),
      ),
    );
  }
}