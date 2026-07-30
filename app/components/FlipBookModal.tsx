'use client';

import React, {
  forwardRef,
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
} from 'react';
import HTMLFlipBook from 'react-pageflip';

export type Book = {
  id: number;
  title: string;
  cover: string;
  pages: string[];
};

type BookCoverProps = {
  src: string;
  title: string;
  back?: boolean;
};

const BookCover = forwardRef<HTMLDivElement, BookCoverProps>(
  function BookCover({ src, title, back = false }, ref) {
    return (
      <div
        ref={ref}
        data-density="hard"
        className="relative h-full w-full overflow-hidden bg-[#243129]"
      >
        {/* eslint-disable-next-line @next/next/no-img-element -- External placeholder/dynamic book cover URL */}
        <img
          src={src}
          alt={back ? `${title} back cover` : `${title} cover`}
          className="h-full w-full object-cover"
        />

        {!back && (
          <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-end bg-gradient-to-t from-black/60 via-black/10 to-transparent pb-9 text-center">
            <span className="rounded-full border border-white/25 bg-black/20 px-4 py-2 text-[10px] font-bold tracking-[0.2em] text-white backdrop-blur-sm">
              CLICK TO OPEN
            </span>
          </div>
        )}
      </div>
    );
  }
);

BookCover.displayName = 'BookCover';

type BookPageProps = {
  src: string;
  title: string;
  pageNumber: number;
};

const BookPage = forwardRef<HTMLDivElement, BookPageProps>(
  function BookPage({ src, title, pageNumber }, ref) {
    return (
      <div
        ref={ref}
        className="relative h-full w-full overflow-hidden bg-[#f4f2ec]"
      >
        {/* eslint-disable-next-line @next/next/no-img-element -- External placeholder/dynamic book page URL */}
        <img
          src={src}
          alt={`${title} หน้า ${pageNumber}`}
          className="h-full w-full object-cover"
        />

        {/* ลายกระดาษบาง ๆ เพื่อให้หน้าตัวอย่างดูเหมือนหนังสือจริง โดยไม่บังเนื้อหา */}
        <div
          aria-hidden="true"
          className="pointer-events-none absolute inset-0 opacity-35 mix-blend-multiply"
          style={{
            backgroundImage: [
              'repeating-linear-gradient(to bottom, transparent 0, transparent 30px, rgba(154,114,87,0.12) 31px, transparent 32px)',
              'radial-gradient(rgba(36,49,41,0.08) 0.7px, transparent 0.8px)',
            ].join(', '),
            backgroundSize: '100% 32px, 12px 12px',
          }}
        />
        <div
          aria-hidden="true"
          className="pointer-events-none absolute inset-5 rounded-lg border border-[#9a7257]/20"
        />

        <div className="pointer-events-none absolute inset-x-0 bottom-0 flex justify-center bg-gradient-to-t from-black/30 to-transparent pb-4 pt-12">
          <span className="rounded-full bg-white/90 px-3 py-1 text-[10px] font-bold tracking-widest text-[#243129] shadow-sm">
            {pageNumber}
          </span>
        </div>
      </div>
    );
  }
);

BookPage.displayName = 'BookPage';

function useBookSize() {
  const [size, setSize] = useState({
    width: 410,
    height: 574,
    isDesktop: true,
    key: '410x574-desktop',
  });

  useLayoutEffect(() => {
    const updateSize = () => {
      const isDesktop = window.innerWidth >= 900;

      // สัดส่วน A4 แนวตั้งประมาณ 800 x 1120
      const pageRatio = 800 / 1120;

      // เว้นที่ให้หัวข้อ ปุ่ม และขอบหน้าจอ
      const verticalSpace = isDesktop ? 185 : 240;
      const horizontalSpace = isDesktop ? 110 : 80;

      const usableHeight = Math.max(
        300,
        window.innerHeight - verticalSpace,
      );

      const usableWidth = Math.max(
        260,
        window.innerWidth - horizontalSpace,
      );

      // จอคอมต้องเผื่อพื้นที่ไว้ 2 หน้า
      const widthFromScreen = isDesktop ? usableWidth / 2 : usableWidth;
      const widthFromHeight = usableHeight * pageRatio;

      const width = Math.floor(
        Math.min(520, widthFromScreen, widthFromHeight),
      );

      const height = Math.floor(width / pageRatio);

      setSize({
        width,
        height,
        isDesktop,
        key: `${width}x${height}-${isDesktop ? 'desktop' : 'mobile'}`,
      });
    };

    updateSize();

    window.addEventListener('resize', updateSize);

    return () => {
      window.removeEventListener('resize', updateSize);
    };
  }, []);

  return size;
}

type PageFlipApi = {
  flipPrev: () => void;
  flipNext: () => void;
  turnToPage: (page: number) => void;
};

type FlipBookHandle = {
  pageFlip?: () => PageFlipApi;
  getPageFlip?: () => PageFlipApi;
};

export default function FlipBookModal({
  book,
  onClose,
}: {
  book: Book;
  onClose: () => void;
}) {
  const flipBookRef = useRef<FlipBookHandle | null>(null);

  const size = useBookSize();
  const currentKey = `${book.id}-${size.key}`;
  const [lastKey, setLastKey] = useState(currentKey);
  const [bookReady, setBookReady] = useState(false);
  const [currentPage, setCurrentPage] = useState(0);

  if (lastKey !== currentKey) {
    setLastKey(currentKey);
    setBookReady(false);
    setCurrentPage(0);
  }

  const getPageFlip = () => {
    return (
      flipBookRef.current?.pageFlip?.() ??
      flipBookRef.current?.getPageFlip?.()
    );
  };

  // หน้าแรก = ปกหน้า
  const isFrontCover = currentPage <= 0;

  // จำนวนทั้งหมดคือ ปกหน้า + เนื้อหา + ปกหลัง
  const isBackCover = currentPage >= book.pages.length + 1;

  const isBookOpen =
    size.isDesktop && !isFrontCover && !isBackCover;

  /*
    ปกหน้า: library วางไว้ช่องขวา จึงเลื่อน canvas กลับซ้าย 1 หน้า
    หนังสือกาง: ใช้ 2 หน้าเต็ม จัดกลางตามปกติ
    ปกหลัง: อยู่ฝั่งซ้าย จึงไม่ต้องเลื่อน
  */
  const stageWidth = isBookOpen ? size.width * 2 : size.width;

  const flipBookOffsetX = size.isDesktop && isFrontCover ? -size.width : 0;

  useEffect(() => {
    const html = document.documentElement;
    const body = document.body;

    const scrollbarWidth = window.innerWidth - html.clientWidth;

    const oldHtmlOverflow = html.style.overflow;
    const oldBodyOverflow = body.style.overflow;
    const oldBodyPaddingRight = body.style.paddingRight;

    html.style.overflow = 'hidden';
    body.style.overflow = 'hidden';

    if (scrollbarWidth > 0) {
      body.style.paddingRight = `${scrollbarWidth}px`;
    }

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        onClose();
      }

      if (event.key === 'ArrowLeft') {
        getPageFlip()?.flipPrev();
      }

      if (event.key === 'ArrowRight') {
        getPageFlip()?.flipNext();
      }
    };

    window.addEventListener('keydown', handleKeyDown);

    return () => {
      html.style.overflow = oldHtmlOverflow;
      body.style.overflow = oldBodyOverflow;
      body.style.paddingRight = oldBodyPaddingRight;

      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [onClose]);

  useEffect(() => {
    const timeout = window.setTimeout(() => {
      getPageFlip()?.turnToPage(0);
      setBookReady(true);
    }, 80);

    return () => {
      window.clearTimeout(timeout);
    };
  }, [currentKey]);

  return (
    <div
      className="fixed inset-0 z-[999] h-[100dvh] w-screen bg-black/60 backdrop-blur-sm"
      onClick={onClose}
    >
      <div className="flex h-full w-full items-center justify-center px-4 py-5 sm:px-6">
        {/* กล่องนี้มีขนาดตามสถานะหนังสือ จึงจัดกลางจริง */}
        <div
          className="relative overflow-visible transition-[width] duration-500 ease-[cubic-bezier(0.22,1,0.36,1)]"
          style={{
            width: `${stageWidth}px`,
            height: `${size.height}px`,
          }}
          onClick={(event) => event.stopPropagation()}
        >
          {/* เงาใต้หนังสือ */}
          <div
            className="pointer-events-none absolute left-1/2 top-[91%] h-10 -translate-x-1/2 rounded-full bg-black/20 blur-2xl transition-all duration-500 sm:h-14"
            style={{
              width: isBookOpen ? '78%' : '65%',
            }}
          />

          <div
            className="absolute left-0 top-0 transition-transform duration-500 ease-[cubic-bezier(0.22,1,0.36,1)]"
            style={{
              transform: `translateX(${flipBookOffsetX}px)`,
            }}
          >
            <div
              className={
                bookReady
                  ? 'pedebook-floating-book'
                  : 'pointer-events-none opacity-0'
              }
            >
              {/* @ts-expect-error -- react-pageflip types are incomplete */}
              <HTMLFlipBook
                key={`${book.id}-${size.key}`}
                ref={flipBookRef}
                width={size.width}
                height={size.height}
                size="fixed"
                minWidth={150}
                maxWidth={520}
                minHeight={210}
                maxHeight={728}
                drawShadow
                maxShadowOpacity={0.5}
                flippingTime={900}
                startZIndex={10}
                autoSize={false}
                usePortrait={!size.isDesktop}
                showCover={true}
                mobileScrollSupport
                className="pedebook-flipbook"
                onFlip={(event: { data: number }) => {
                  setCurrentPage(event.data);
                }}
              >
                <BookCover src={book.cover} title={book.title} />

                {book.pages.map((page, index) => (
                  <BookPage
                    key={`${book.id}-page-${index}`}
                    src={page}
                    title={book.title}
                    pageNumber={index + 1}
                  />
                ))}

                <BookCover
                  src={book.cover}
                  title={book.title}
                  back
                />
              </HTMLFlipBook>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
