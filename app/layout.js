import './globals.css'

export const metadata = {
  title: 'Nem Admin – Quản trị quán nem',
  description: 'Trang quản trị nội bộ cho quán nem',
}

export default function RootLayout({ children }) {
  return (
    <html lang="vi">
      <body>{children}</body>
    </html>
  )
}
