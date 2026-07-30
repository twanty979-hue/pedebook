import React from 'react';

function resolveSiteUrl(): string {
  const raw = process.env.NEXT_PUBLIC_SITE_URL;

  if (process.env.NODE_ENV === 'production') {
    if (!raw) {
      throw new Error(
        '[SEO] NEXT_PUBLIC_SITE_URL is required for production builds. ' +
        'Set it to your real domain (e.g. https://example.com).',
      );
    }

    let parsed: URL;
    try {
      parsed = new URL(raw.trim());
    } catch {
      throw new Error(
        `[SEO] NEXT_PUBLIC_SITE_URL must be a valid URL in production. Got: "${raw}"`,
      );
    }

    if (parsed.protocol !== 'https:') {
      throw new Error(
        `[SEO] NEXT_PUBLIC_SITE_URL must use HTTPS protocol in production. Got: "${raw}"`,
      );
    }

    return parsed.origin;
  }

  // Development fallback
  if (raw) {
    try {
      const parsed = new URL(raw.trim());
      return parsed.origin;
    } catch {
      // fallback to localhost if invalid in development
    }
  }
  return 'http://localhost:3000';
}

export const SEO_CONFIG = {
  siteUrl: resolveSiteUrl(),
  siteName: process.env.NEXT_PUBLIC_SITE_NAME || 'Pedebook',
  googleSiteVerification: process.env.GOOGLE_SITE_VERIFICATION || '',
};

/**
 * Returns absolute URL for a given path using SITE_URL.
 */
export function absoluteUrl(path: string): string {
  const base = SEO_CONFIG.siteUrl.replace(/\/$/, '');
  const cleanPath = path.startsWith('/') ? path : `/${path}`;
  return `${base}${cleanPath}`;
}

/**
 * Returns canonical URL for a given path.
 */
export function getCanonicalUrl(path: string): string {
  return absoluteUrl(path);
}

// JSON-LD Script Component for structured data
interface JsonLdProps {
  data: Record<string, unknown> | Array<Record<string, unknown>>;
}

export function JsonLd({ data }: JsonLdProps) {
  return React.createElement('script', {
    type: 'application/ld+json',
    dangerouslySetInnerHTML: {
      __html: JSON.stringify(data).replace(/</g, '\\u003c'),
    },
  });
}

// Organization Schema Generator
export function generateOrganizationJsonLd(url: string) {
  return {
    '@context': 'https://schema.org',
    '@type': 'Organization',
    '@id': `${url}#organization`,
    name: SEO_CONFIG.siteName,
    url: url,
    logo: absoluteUrl('/pedebook-logo-lockup.png'),
  };
}

// WebSite Schema Generator
export function generateWebSiteJsonLd(url: string) {
  return {
    '@context': 'https://schema.org',
    '@type': 'WebSite',
    '@id': `${url}#website`,
    name: SEO_CONFIG.siteName,
    url: url,
    publisher: {
      '@id': `${url}#organization`,
    },
  };
}

// WebApplication Schema Generator (for Pedebook tool)
export function generateWebApplicationJsonLd(url: string) {
  return {
    '@context': 'https://schema.org',
    '@type': 'WebApplication',
    '@id': `${url}#webapplication`,
    name: SEO_CONFIG.siteName,
    url: url,
    applicationCategory: 'BusinessApplication',
    operatingSystem: 'All',
    browserRequirements: 'Requires HTML5 compatible browser',
    publisher: {
      '@id': `${url}#organization`,
    },
  };
}

// FAQPage Schema Generator
export function generateFAQJsonLd(url: string, faqs: Array<{ question: string; answer: string }>) {
  return {
    '@context': 'https://schema.org',
    '@type': 'FAQPage',
    '@id': `${url}#faq`,
    mainEntity: faqs.map((faq) => ({
      '@type': 'Question',
      name: faq.question,
      acceptedAnswer: {
        '@type': 'Answer',
        text: faq.answer,
      },
    })),
  };
}

export function generateDigitalDocumentJsonLd({
  url,
  title,
  description,
  image,
  dateModified,
}: {
  url: string;
  title: string;
  description: string;
  image: string;
  dateModified?: string;
}) {
  return {
    '@context': 'https://schema.org',
    '@type': 'DigitalDocument',
    '@id': `${url}#document`,
    name: title,
    description,
    url,
    image,
    encodingFormat: 'application/pdf',
    isAccessibleForFree: true,
    ...(dateModified ? { dateModified } : {}),
    publisher: {
      '@type': 'Organization',
      name: SEO_CONFIG.siteName,
      url: SEO_CONFIG.siteUrl,
    },
  };
}
