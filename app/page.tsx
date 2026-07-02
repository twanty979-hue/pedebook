"use client";

import React, {
  forwardRef,
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
} from "react";
import HTMLFlipBook from "react-pageflip";
import { onAuthStateChanged, signOut, User } from "firebase/auth";
import { auth } from "./src/lib/firebase";

type Book = {
  id: number;
  title: string;
  cover: string;
  pages: string[];
};

const mockBooks: Book[] = [
  {
    id: 1,
    title: "LIVING",
    cover:
      "https://placehold.co/800x1120/243129/ffffff?text=LIVING+2026",
    pages: [
      "https://placehold.co/800x1120/f4f2ec/243129?text=LIVING+2026",
      "https://placehold.co/800x1120/e8dcc7/243129?text=Welcome+Home",
      "https://placehold.co/800x1120/efe7d8/243129?text=Warm+Spaces",
      "https://placehold.co/800x1120/f4f2ec/243129?text=Materials+and+Details",
      "https://placehold.co/800x1120/e8dcc7/243129?text=Comfort+in+Every+Room",
      "https://placehold.co/800x1120/243129/ffffff?text=Thank+You",
    ],
  },
  {
    id: 2,
    title: "SPACE",
    cover:
      "https://placehold.co/800x1120/9a7257/ffffff?text=SPACE+MAG",
    pages: [
      "https://placehold.co/800x1120/f8f3eb/412e24?text=The+New+Collection",
      "https://placehold.co/800x1120/e7d6c7/412e24?text=Designed+for+Living",
      "https://placehold.co/800x1120/f8f3eb/412e24?text=Your+Next+Room",
      "https://placehold.co/800x1120/e7d6c7/412e24?text=Explore+More",
      "https://placehold.co/800x1120/f8f3eb/412e24?text=Create+Your+Space",
      "https://placehold.co/800x1120/e7d6c7/412e24?text=Pedebook",
    ],
  },
  {
    id: 3,
    title: "NATURE",
    cover:
      "https://placehold.co/800x1120/cdbb9f/17221c?text=NATURE",
    pages: [
      "https://placehold.co/800x1120/f3eddf/17221c?text=Start+Here",
      "https://placehold.co/800x1120/dde0cf/17221c?text=Calm+and+Natural",
      "https://placehold.co/800x1120/f3eddf/17221c?text=Stories+in+Green",
      "https://placehold.co/800x1120/dde0cf/17221c?text=Find+Your+Balance",
      "https://placehold.co/800x1120/f3eddf/17221c?text=See+You+Again",
      "https://placehold.co/800x1120/cdbb9f/17221c?text=Pedebook",
    ],
  },
];

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
  },
);

BookCover.displayName = "BookCover";

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
        <img
          src={src}
          alt={`${title} หน้า ${pageNumber}`}
          className="h-full w-full object-cover"
        />

        <div className="pointer-events-none absolute inset-x-0 bottom-0 flex justify-center bg-gradient-to-t from-black/30 to-transparent pb-4 pt-12">
          <span className="rounded-full bg-white/90 px-3 py-1 text-[10px] font-bold tracking-widest text-[#243129] shadow-sm">
            {pageNumber}
          </span>
        </div>
      </div>
    );
  },
);

BookPage.displayName = "BookPage";

function useBookSize() {
  const [size, setSize] = useState({
    width: 410,
    height: 574,
    isDesktop: true,
    key: "410x574-desktop",
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
        key: `${width}x${height}-${isDesktop ? "desktop" : "mobile"}`,
      });
    };

    updateSize();

    window.addEventListener("resize", updateSize);

    return () => {
      window.removeEventListener("resize", updateSize);
    };
  }, []);

  return size;
}

function FlipBookModal({
  book,
  onClose,
}: {
  book: Book;
  onClose: () => void;
}) {
  const flipBookRef = useRef<any>(null);

  const [bookReady, setBookReady] = useState(false);
  const [currentPage, setCurrentPage] = useState(0);

  const size = useBookSize();

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

    html.style.overflow = "hidden";
    body.style.overflow = "hidden";

    if (scrollbarWidth > 0) {
      body.style.paddingRight = `${scrollbarWidth}px`;
    }

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        onClose();
      }

      if (event.key === "ArrowLeft") {
        getPageFlip()?.flipPrev();
      }

      if (event.key === "ArrowRight") {
        getPageFlip()?.flipNext();
      }
    };

    window.addEventListener("keydown", handleKeyDown);

    return () => {
      html.style.overflow = oldHtmlOverflow;
      body.style.overflow = oldBodyOverflow;
      body.style.paddingRight = oldBodyPaddingRight;

      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [onClose]);

  useEffect(() => {
    setBookReady(false);

    const timeout = window.setTimeout(() => {
      getPageFlip()?.turnToPage(0);

      setCurrentPage(0);
      setBookReady(true);
    }, 80);

    return () => {
      window.clearTimeout(timeout);
    };
  }, [book.id, size.key]);

  return (
    <div
      className="fixed inset-0 z-[999] h-[100dvh] w-screen"
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
              width: isBookOpen ? "78%" : "65%",
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
        ? "pedebook-floating-book"
        : "pointer-events-none opacity-0"
    }
  >
    {/* @ts-ignore */}
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
export default function LandingPage() {
  const [activeBook, setActiveBook] = useState<Book | null>(null);
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
      setUser(currentUser);
    });
    return () => unsubscribe();
  }, []);

  const handleSignOut = async () => {
    try {
      await signOut(auth);
    } catch (error) {
      console.error("Sign out error", error);
    }
  };

  return (
    <main className="min-h-screen overflow-hidden bg-[#f6f4ee] font-sans text-[#17221c]">
      <style
  dangerouslySetInnerHTML={{
    __html: `
      html {
        scrollbar-gutter: stable;
      }

      .pedebook-flipbook .stf__item {
        box-shadow: 0 28px 70px rgba(0, 0, 0, 0.28);
        border-radius: 10px;
        overflow: hidden;
      }

      @keyframes pedebook-floating-book-in {
        0% {
          opacity: 0;
          transform: translateY(40px) scale(0.94) rotateX(8deg);
        }
        100% {
          opacity: 1;
          transform: translateY(0) scale(1) rotateX(0deg);
        }
      }

      @keyframes pedebook-soft-float {
        0%, 100% {
          transform: translateY(0px);
        }
        50% {
          transform: translateY(-8px);
        }
      }

      .pedebook-floating-book {
        animation:
          pedebook-floating-book-in 260ms cubic-bezier(.2,.8,.2,1) both,
          pedebook-soft-float 4s ease-in-out 260ms infinite;
        transform-origin: center center;
        will-change: transform, opacity;
      }

      @keyframes float-slow {
        0%, 100% {
          transform: translateY(0px) rotate(0deg);
        }
        50% {
          transform: translateY(-15px) rotate(2deg);
        }
      }

      .animate-float {
        animation: float-slow 6s ease-in-out infinite;
      }
    `,
  }}
/>

      {activeBook && (
        <FlipBookModal
          book={activeBook}
          onClose={() => setActiveBook(null)}
        />
      )}

      <nav className="relative z-10 flex w-full items-center justify-between px-4 py-6 sm:px-8 lg:px-12">
        <a href="/" className="flex items-center gap-2.5">
          <img
            src="/logo.png"
            alt="Pedebook Logo"
            className="h-10 w-10 rounded-xl object-contain shadow-sm"
          />
          <div className="flex flex-col">
            <span className="text-lg font-bold tracking-tight text-[#17221c] leading-tight">
              Pedebook
            </span>
            <span className="text-[10px] font-semibold text-[#9a7257] tracking-wide leading-none">
              Digital Flipbook Platform
            </span>
          </div>
        </a>

        <div className="flex items-center gap-4">
          {user ? (
            <a
              href="/dashboard"
              className="flex items-center gap-2 rounded-full border border-[#d9d7cd] bg-white/60 px-3 py-1.5 shadow-sm backdrop-blur hover:bg-[#243129]/5 transition-all duration-300 cursor-pointer"
            >
              {user.photoURL ? (
                <img
                  src={user.photoURL}
                  alt={user.displayName || "User Profile"}
                  className="h-7 w-7 rounded-full object-cover"
                  referrerPolicy="no-referrer"
                />
              ) : (
                <span className="grid h-7 w-7 place-items-center rounded-full bg-[#243129] text-xs font-bold text-[#e8dcc7]">
                  {user.email?.charAt(0).toUpperCase() || "U"}
                </span>
              )}
              <div className="hidden flex-col text-left sm:flex">
                <span className="text-xs font-bold leading-tight text-[#17221c]">
                  {user.displayName || "ผู้ใช้งาน"}
                </span>
                <span className="text-[10px] leading-tight text-[#6e746f]">
                  {user.email}
                </span>
              </div>
            </a>
          ) : (
            <div className="flex items-center gap-4">
              <a
                href="/login"
                className="hidden text-sm font-semibold text-[#755a47] transition hover:text-[#243129] sm:block"
              >
                เข้าสู่ระบบ
              </a>

              <a
                href="/login"
                className="rounded-full bg-[#243129] px-6 py-2.5 text-sm font-bold text-[#e8dcc7] shadow-[0_4px_12px_rgba(36,49,41,0.2)] transition hover:bg-[#314238]"
              >
                เริ่มสร้างฟรี
              </a>
            </div>
          )}
        </div>
      </nav>

      <section className="relative flex flex-col items-center justify-center py-10 text-center lg:py-20 overflow-hidden">
        <div className="animate-float absolute left-1/2 top-[30%] h-[400px] w-[400px] -translate-x-1/2 -translate-y-1/2 rounded-full bg-[#d3b894]/30 blur-[90px] lg:h-[600px] lg:w-[600px]" />
 
        <div className="relative z-10 mx-auto max-w-[1200px] px-5">
          <div className="mb-6 inline-flex items-center gap-2 rounded-full border border-[#d9d7cd] bg-white/60 px-4 py-2 text-xs font-bold uppercase tracking-[0.15em] text-[#755a47] shadow-sm backdrop-blur">
            <span className="h-2 w-2 animate-pulse rounded-full bg-[#9a7257]" />
            Digital Publishing Platform
          </div>

          <h1 className="text-4xl font-medium leading-[1.05] tracking-tight text-[#17221c] sm:text-5xl lg:text-[72px]">
            Publish Interactive <br className="hidden sm:block" />
            Catalogs &{" "}
            <span className="font-serif italic text-[#9a7257]">
              Brochures Online
            </span>
          </h1>

          <p className="mx-auto mt-6 max-w-2xl text-lg text-[#6e746f] sm:text-xl font-sans">
            เปลี่ยนไฟล์ PDF ของคุณให้เป็นสมุดเปิดอ่านดิจิทัล (Digital Flipbook) พลิกสมจริงแบบ 3D<br className="hidden sm:block" />
            <span className="font-semibold text-[#8a654d]">
              ออกแบบสวยงาม รองรับทุกอุปกรณ์ทั้ง iOS & Android สแกนเข้าอ่านได้ทันทีผ่าน QR Code
            </span>
          </p>

          {/* ชั้นหนังสือตัวอย่าง Flipbook */}
          <div className="mb-16 mt-20 flex flex-col items-center justify-center gap-10">
            <div className="relative flex w-full max-w-[900px] items-end justify-center gap-4 border-b-[20px] border-[#c4a77d] px-4 pb-1 shadow-[0_35px_40px_-15px_rgba(154,114,87,0.3)] sm:gap-12 sm:px-12 lg:border-b-[24px]">
              <div className="absolute -bottom-[24px] left-10 h-8 w-6 rounded-b-sm bg-[#a88a5d] shadow-inner lg:-bottom-[30px] lg:h-10 lg:w-8" />
              <div className="absolute -bottom-[24px] right-10 h-8 w-6 rounded-b-sm bg-[#a88a5d] shadow-inner lg:-bottom-[30px] lg:h-10 lg:w-8" />

              {mockBooks.map((book, index) => (
                <button
                  key={book.id}
                  type="button"
                  onClick={() => setActiveBook(book)}
                  className={`group relative z-10 cursor-pointer text-left outline-none transition-all duration-500 ease-out hover:-translate-y-12 hover:scale-110 focus-visible:ring-4 focus-visible:ring-[#9a7257]/45 ${
                    index === 1 ? "z-20 scale-105 hover:scale-115" : ""
                  }`}
                >
                  <div className="relative h-[180px] w-[110px] overflow-hidden rounded-r-[4px] border-l-[3px] border-white/80 shadow-[-10px_10px_20px_rgba(50,43,34,0.2)] transition-all duration-500 group-hover:shadow-[-20px_25px_40px_rgba(50,43,34,0.3)] sm:h-[260px] sm:w-[170px] lg:h-[300px] lg:w-[200px]">
                    <img
                      src={book.cover}
                      alt={book.title}
                      className="h-full w-full object-cover transition-transform duration-700 group-hover:scale-105"
                    />

                    {index === 0 && (
                      <span className="absolute -right-7 top-5 rotate-45 bg-[#9a7257] px-8 py-1.5 text-[10px] font-bold text-white shadow-md">
                        NEW
                      </span>
                    )}

                    <span className="absolute inset-0 flex items-center justify-center bg-black/40 opacity-0 backdrop-blur-[2px] transition-opacity duration-300 group-hover:opacity-100">
                      <span className="rounded-full bg-white/20 px-4 py-2 text-xs font-bold tracking-widest text-white backdrop-blur-md">
                        CLICK TO READ
                      </span>
                    </span>
                  </div>

                  <span className="absolute -bottom-1 left-0 h-1.5 w-full bg-[#e8dcc7]" />
                  <span className="absolute -right-1 top-0 h-full w-1.5 origin-bottom-right skew-y-[45deg] bg-[#d3b894]" />
                </button>
              ))}
            </div>
          </div>
        </div>
      </section>
    </main>
  );
}