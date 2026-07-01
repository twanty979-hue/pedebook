import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'pub-2ffbbdf16e914d7ea107c1266b03387b.r2.dev', // 👈 เอาอันนี้มาใส่ตรงๆ เลยครับนาย
        port: '',
        pathname: '/**',
      },
    ],
  },
};

export default nextConfig;