# ChamCongHieuIT

Ứng dụng chấm công cá nhân dành cho lịch làm việc cố định. App chạy offline,
lưu dữ liệu trên thiết bị và xuất báo cáo PDF theo tháng.

## Chức năng hiện có

- Thiết lập giờ bắt đầu, giờ kết thúc, thời gian nghỉ và ngày làm trong tuần.
- Tạo toàn bộ ngày công trong tháng bằng một nút.
- Xóa nhanh toàn bộ dữ liệu một tháng để tạo lại lịch.
- Thêm, sửa hoặc xóa từng ngày; hỗ trợ nghỉ phép, nghỉ không lương và nghỉ lễ.
- Tự tính tổng giờ làm và tăng ca.
- Tạo, xóa, tạo lại và chia sẻ báo cáo PDF.
- Sao lưu toàn bộ ngày công thành tệp JSON và khôi phục lại khi cần.
- Hiển thị tháng, ngày và thứ bằng tiếng Việt.
- App icon riêng và giao diện tối ưu cho cả chế độ sáng/tối.
- Phản hồi rung tinh tế, có thể tắt trong Cài đặt.
- Không cần tài khoản hoặc máy chủ.

## Yêu cầu

- iOS 17 trở lên.
- SwiftUI, SwiftData và UIKit PDF renderer.
- XcodeGen để sinh `ChamCongHieuIT.xcodeproj` từ `project.yml`.

## Build bằng GitHub Actions

1. Tạo repository GitHub mới.
2. Đưa toàn bộ nội dung thư mục này lên nhánh `main`.
3. Mở tab **Actions** và chọn workflow **iOS Unsigned IPA**.
4. Chọn **Run workflow**, hoặc chỉ cần push một commit mới lên `main`.
5. Tải IPA trong phần **Releases** của repository.

Workflow chạy trên macOS, tự cài XcodeGen, sinh Xcode project và build
`ChamCongHieuIT-v0.1.x.ipa`.

## Lưu ý cài đặt

IPA được GitHub tạo ra chưa có chữ ký. Bạn cần ký/sideload bằng công cụ phù hợp
hoặc dùng chứng chỉ Apple Developer của riêng mình trước khi cài lên iPhone.

## Build trên máy Mac

```bash
brew install xcodegen
xcodegen generate
open ChamCongHieuIT.xcodeproj
```
