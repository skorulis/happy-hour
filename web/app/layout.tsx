import { AnalyticsProvider } from "@/components/AnalyticsProvider";
import { SiteFooter } from "@/components/SiteFooter";
import { SiteNav } from "@/components/SiteNav";
import { siteUrl } from "@/lib/site-url";
import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl()),
  title: "DuskRoute",
  description: "Find happy hour deals near you as the day fades into night.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <body className="flex min-h-full flex-col bg-background text-foreground">
        <AnalyticsProvider>
          <SiteNav />
          <main className="flex flex-1 flex-col bg-transparent">
            {children}
          </main>
          <SiteFooter />
        </AnalyticsProvider>
      </body>
    </html>
  );
}
