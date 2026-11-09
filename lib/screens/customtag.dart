import 'package:disclosure_app_fl/providers/auth_provider.dart';
import 'package:disclosure_app_fl/providers/custom_tags_provider.dart';
import 'package:disclosure_app_fl/providers/user_settings_provider.dart';
import 'package:disclosure_app_fl/widgets/bottom_text_field_with_icon.dart';
import 'package:disclosure_app_fl/widgets/dismissible_delete_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomTagScreen extends ConsumerWidget {
  const CustomTagScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("カスタムタグ設定")),
      body: _buildBody(context, ref),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final userDocAsync = ref.watch(userDocStreamProvider);

    return userDocAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            Icon(Icons.error_outline, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text('カスタムタグの読み込みに失敗しました'),
          ],
        ),
      ),
      data: (_) {
        final tags = ref.watch(customTagsProvider);
        return SafeArea(
          child: Column(
            children: [
              Expanded(
                child: tags.isNotEmpty
                    ? ListView.builder(
                        itemCount: tags.length,
                        itemBuilder: (context, index) {
                          final tag = tags[index];
                          return Dismissible(
                            key: ValueKey(tag),
                            background:
                                const DismissibleDeleteBackground.left(),
                            secondaryBackground:
                                const DismissibleDeleteBackground.right(),
                            child: ListTile(
                              title: Text(tag),
                            ),
                            onDismissed: (direction) {
                              final action =
                                  ref.read(customTagsActionProvider.notifier);
                              final uid = ref.read(currentUserProvider)?.uid;
                              if (uid != null) {
                                action.remove(uid, tag);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: const Text("削除しました"),
                                  action: SnackBarAction(
                                    label: "取り消す",
                                    onPressed: () {
                                      action.add(uid, tag);
                                    },
                                  ),
                                ));
                              }
                            },
                          );
                        },
                      )
                    : Container(
                        alignment: AlignmentDirectional.center,
                        child: const Text("カスタムタグはありません"),
                      ),
              ),
              const Divider(),
              BottomTextFieldWithIcon(
                onSubmit: (tag) {
                  final uid = ref.read(currentUserProvider)?.uid;
                  if (uid != null && tag.trim().isNotEmpty) {
                    ref
                        .read(customTagsActionProvider.notifier)
                        .add(uid, tag.trim());
                  }
                },
                hintText: 'タグ名',
              )
            ],
          ),
        );
      },
    );
  }
}
