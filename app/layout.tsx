import type { Metadata } from "next";
import "./globals.css";
import { SettingsProvider } from "@/lib/contexts/settings-context";
import { AuthErrorHandler } from "@/components/AuthErrorHandler";
import { Toaster } from 'sonner';

import { createClient } from "@/lib/supabase/server";

export async function generateMetadata(): Promise<Metadata> {
  const supabase = await createClient();
  const { data } = await supabase
    .from('t_settings')
    .select('value')
    .eq('key', 'company_info')
    .maybeSingle();

  const companyInfo = data?.value as any;
  const orgName = companyInfo?.name || "RSUD BENDAN";
  const appName = companyInfo?.appName || "Aplikasi PINTAR-JP";

  return {
    title: `${orgName} - ${appName}`,
    description: "Sistem Manajemen Insentif dan KPI",
    icons: {
      icon: '/favicon.svg',
    },
  };
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="id" suppressHydrationWarning>
      <body className="font-sans antialiased" suppressHydrationWarning>
        <AuthErrorHandler />
        <SettingsProvider>
          {children}
        </SettingsProvider>
        <Toaster position="top-right" richColors />
      </body>
    </html>
  );
}
