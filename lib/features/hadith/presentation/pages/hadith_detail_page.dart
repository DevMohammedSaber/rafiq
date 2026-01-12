import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cubit/hadith_detail_cubit.dart';
import 'dart:ui' as ui;

class HadithDetailPage extends StatefulWidget {
  final String uid;
  const HadithDetailPage({super.key, required this.uid});

  @override
  State<HadithDetailPage> createState() => _HadithDetailPageState();
}

class _HadithDetailPageState extends State<HadithDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<HadithDetailCubit>().loadHadith(widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          BlocBuilder<HadithDetailCubit, HadithDetailState>(
            builder: (context, state) {
              if (state is HadithDetailLoaded) {
                return IconButton(
                  icon: Icon(
                    state.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: state.isFavorite ? Colors.red : null,
                  ),
                  onPressed: () =>
                      context.read<HadithDetailCubit>().toggleFavorite(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  final RenderBox? box =
                      context.findRenderObject() as RenderBox?;
                  final state = context.read<HadithDetailCubit>().state;
                  if (state is HadithDetailLoaded) {
                    Share.share(
                      state.item.textAr,
                      sharePositionOrigin: box != null
                          ? box.localToGlobal(Offset.zero) & box.size
                          : null,
                    );
                  }
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              final state = context.read<HadithDetailCubit>().state;
              if (state is HadithDetailLoaded) {
                Clipboard.setData(ClipboardData(text: state.item.textAr));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("hadith.copied".tr())));
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<HadithDetailCubit, HadithDetailState>(
        builder: (context, state) {
          if (state is HadithDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HadithDetailLoaded) {
            final item = state.item;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (item.chapter != null && item.chapter!.isNotEmpty) ...[
                    Text(
                      item.chapter!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    item.textAr,
                    textDirection: ui.TextDirection.rtl,
                    textAlign: TextAlign.justify,
                    style: GoogleFonts.amiri(fontSize: 22, height: 1.8),
                  ),
                  const SizedBox(height: 32),
                  if (item.number != null)
                    Text(
                      "${"hadith.title".tr()} #${item.number}",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            );
          }

          if (state is HadithDetailError) {
            return Center(child: Text(state.message));
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
