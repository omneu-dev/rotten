import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/update_request.dart';

class PostListItem extends StatelessWidget {
  final UpdateRequest post;
  final VoidCallback? onTap;

  const PostListItem({super.key, required this.post, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 82,
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 82,
            decoration: ShapeDecoration(
              color: const Color(0xFFEAECF0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          style: const TextStyle(
                            color: Color(0xFF363A48),
                            fontSize: 16,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                            height: 2,
                            letterSpacing: -1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(post.createdAt),
                          style: const TextStyle(
                            color: Color(0xFF495874),
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                            height: 1.29,
                            letterSpacing: -0.20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 24,
                    height: 24,
                    child: SvgPicture.asset(
                      'assets/images/ic_ic_arrowsmall_right.svg',
                      width: 24,
                      height: 24,
                      color: const Color(0xFF495874),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
