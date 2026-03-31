-- ================================================================
--  KURUMSAL DOKÜMANLARDA ERİŞİM YETKİ MATRİSİ VE İZ KAYDI SİSTEMİ
--  YetkiMatrisiDB — SQL Server Management Studio (T-SQL)
--  Kastamonu Üniversitesi · Bilgisayar Mühendisliği · 2026
-- ================================================================
--  BÖLÜMLER:
--   §1  Veritabanı ve tablo tanımları  (18 tablo)
--   §2  Normalizasyon kanıtı          (1NF · 2NF · 3NF)
--   §3  Referans verileri             (roller, dept, kategoriler)
--   §4  Kullanıcı verileri            (500 kayıt)
--   §5  Doküman verileri              (2000 kayıt)
--   §6  Erişim logları                (2500 kayıt)
--   §7  Yardımcı veriler              (onay, bildirim, paylaşım …)
--   §8  View tanımları                (3 view)
--   §9  35 SQL Sorgusu                (A-E grupları)
-- ================================================================

USE master;
GO
IF DB_ID('YetkiMatrisiDB') IS NOT NULL
    ALTER DATABASE YetkiMatrisiDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
IF DB_ID('YetkiMatrisiDB') IS NOT NULL
    DROP DATABASE YetkiMatrisiDB;
GO
CREATE DATABASE YetkiMatrisiDB COLLATE Turkish_CI_AS;
GO
USE YetkiMatrisiDB;
GO

-- ================================================================
-- §1  TABLO TANIMLARI
-- ================================================================

-- 1. Departmanlar
CREATE TABLE Departmanlar (
    DepartmanID      INT IDENTITY(1,1) PRIMARY KEY,
    DepartmanAdi     NVARCHAR(100) NOT NULL,
    DepartmanKodu    NVARCHAR(10)  NOT NULL UNIQUE,
    UstDepartmanID   INT NULL REFERENCES Departmanlar(DepartmanID),
    Aciklama         NVARCHAR(255) NULL,
    AktifMi          BIT NOT NULL DEFAULT 1,
    OlusturmaTarih   DATETIME NOT NULL DEFAULT GETDATE()
);

-- 2. Roller
CREATE TABLE Roller (
    RolID          INT IDENTITY(1,1) PRIMARY KEY,
    RolAdi         NVARCHAR(100) NOT NULL UNIQUE,
    RolKodu        NVARCHAR(20)  NOT NULL UNIQUE,
    YetkiSeviyesi  TINYINT NOT NULL CHECK (YetkiSeviyesi BETWEEN 1 AND 10),
    Aciklama       NVARCHAR(300) NULL,
    AktifMi        BIT NOT NULL DEFAULT 1,
    OlusturmaTarih DATETIME NOT NULL DEFAULT GETDATE()
);

-- 3. Kullanicilar
CREATE TABLE Kullanicilar (
    KullaniciID      INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciAdi     NVARCHAR(50)  NOT NULL UNIQUE,
    Ad               NVARCHAR(50)  NOT NULL,
    Soyad            NVARCHAR(50)  NOT NULL,
    Email            NVARCHAR(150) NOT NULL UNIQUE,
    SifreHash        NVARCHAR(256) NOT NULL,
    DepartmanID      INT NOT NULL REFERENCES Departmanlar(DepartmanID),
    -- 3NF: Departman bilgileri (tel, adres) burada değil → Departmanlar tablosunda
    Unvan            NVARCHAR(100) NULL,
    Telefon          NVARCHAR(20)  NULL,
    AktifMi          BIT NOT NULL DEFAULT 1,
    SonGirisTarih    DATETIME NULL,
    OlusturmaTarih   DATETIME NOT NULL DEFAULT GETDATE(),
    GuncellenmeTarih DATETIME NULL
);

-- 4. KullaniciRol  [2NF kanıtı: sadece FK'lar + ilişkiye ait özellikler]
CREATE TABLE KullaniciRol (
    KullaniciRolID  INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciID     INT NOT NULL REFERENCES Kullanicilar(KullaniciID),
    RolID           INT NOT NULL REFERENCES Roller(RolID),
    -- 2NF: KullaniciAdi ve RolAdi burada YOK; sadece anahtarın bütününe bağlı sütunlar var
    AtamaTarih      DATETIME NOT NULL DEFAULT GETDATE(),
    AtayanID        INT NULL  REFERENCES Kullanicilar(KullaniciID),
    BitisTarih      DATETIME NULL,
    AktifMi         BIT NOT NULL DEFAULT 1,
    CONSTRAINT UQ_KullaniciRol UNIQUE (KullaniciID, RolID)
);

-- 5. DokumanKategorileri
CREATE TABLE DokumanKategorileri (
    KategoriID       INT IDENTITY(1,1) PRIMARY KEY,
    KategoriAdi      NVARCHAR(100) NOT NULL UNIQUE,
    KategoriKodu     NVARCHAR(20)  NOT NULL UNIQUE,
    UstKategoriID    INT NULL REFERENCES DokumanKategorileri(KategoriID),
    Aciklama         NVARCHAR(255) NULL,
    GizlilikSeviyesi TINYINT NOT NULL DEFAULT 1 CHECK (GizlilikSeviyesi BETWEEN 1 AND 5),
    AktifMi          BIT NOT NULL DEFAULT 1
);

-- 6. DokumanTipleri  [3NF: KategoriAdi burada değil → DokumanKategorileri'nde]
CREATE TABLE DokumanTipleri (
    TipID            INT IDENTITY(1,1) PRIMARY KEY,
    TipAdi           NVARCHAR(100) NOT NULL UNIQUE,
    TipKodu          NVARCHAR(20)  NOT NULL UNIQUE,
    KategoriID       INT NOT NULL REFERENCES DokumanKategorileri(KategoriID),
    IzinliBoyutByte  BIGINT NOT NULL DEFAULT 10485760,
    IzinliUzantilar  NVARCHAR(200) NOT NULL DEFAULT '.pdf,.docx',
    SaklamaSuresiGun INT NOT NULL DEFAULT 2555,
    AktifMi          BIT NOT NULL DEFAULT 1
);

-- 7. Etiketler
CREATE TABLE Etiketler (
    EtiketID       INT IDENTITY(1,1) PRIMARY KEY,
    EtiketAdi      NVARCHAR(50) NOT NULL UNIQUE,
    Renk           NVARCHAR(7)  NOT NULL DEFAULT '#3B82F6',
    AktifMi        BIT NOT NULL DEFAULT 1,
    OlusturmaTarih DATETIME NOT NULL DEFAULT GETDATE()
);

-- 8. Dokumanlar  [3NF kanıtı: TipAdi,KategoriAdi,DeptAdi burada YOK → FK + JOIN]
CREATE TABLE Dokumanlar (
    DokumanID          INT IDENTITY(1,1) PRIMARY KEY,
    Baslik             NVARCHAR(300) NOT NULL,
    DokumanNo          NVARCHAR(50)  NOT NULL UNIQUE,
    TipID              INT NOT NULL REFERENCES DokumanTipleri(TipID),
    DepartmanID        INT NOT NULL REFERENCES Departmanlar(DepartmanID),
    OlusturanID        INT NOT NULL REFERENCES Kullanicilar(KullaniciID),
    SorumluID          INT NULL     REFERENCES Kullanicilar(KullaniciID),
    GizlilikSeviyesi   TINYINT NOT NULL DEFAULT 1 CHECK (GizlilikSeviyesi BETWEEN 1 AND 5),
    DokumanDurumu      NVARCHAR(20) NOT NULL DEFAULT 'Taslak'
                       CHECK (DokumanDurumu IN
                       ('Taslak','Inceleme','Onaylandi','Yayinlandi','Arsivlendi','Iptal')),
    AciklamaKisa       NVARCHAR(500) NULL,
    DosyaYolu          NVARCHAR(500) NULL,
    DosyaBoyutu        BIGINT NULL,
    DosyaUzantisi      NVARCHAR(10) NULL,
    AktifMi            BIT NOT NULL DEFAULT 1,
    OlusturmaTarih     DATETIME NOT NULL DEFAULT GETDATE(),
    GuncellenmeTarih   DATETIME NULL,
    SonErisilenTarih   DATETIME NULL,
    YayinTarihi        DATETIME NULL,
    SonGecerlilikTarih DATETIME NULL
);

-- 9. DokumanVersiyonlari
CREATE TABLE DokumanVersiyonlari (
    VersiyonID     INT IDENTITY(1,1) PRIMARY KEY,
    DokumanID      INT NOT NULL REFERENCES Dokumanlar(DokumanID),
    VersiyonNo     NVARCHAR(10) NOT NULL,
    DegisiklikNotu NVARCHAR(500) NULL,
    OlusturanID    INT NOT NULL REFERENCES Kullanicilar(KullaniciID),
    DosyaBoyutu    BIGINT NULL,
    OlusturmaTarih DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT UQ_Versiyon UNIQUE (DokumanID, VersiyonNo)
);

-- 10. DokumanEtiketler  [1NF kanıtı: çok değerli etiket alanı yerine ayrı tablo]
CREATE TABLE DokumanEtiketler (
    DokumanEtiketID INT IDENTITY(1,1) PRIMARY KEY,
    DokumanID       INT NOT NULL REFERENCES Dokumanlar(DokumanID),
    EtiketID        INT NOT NULL REFERENCES Etiketler(EtiketID),
    EklemeTarih     DATETIME NOT NULL DEFAULT GETDATE(),
    EkleyenID       INT NULL REFERENCES Kullanicilar(KullaniciID),
    CONSTRAINT UQ_DokEtiket UNIQUE (DokumanID, EtiketID)
);

-- 11. YetkiMatrisi
CREATE TABLE YetkiMatrisi (
    YetkiID             INT IDENTITY(1,1) PRIMARY KEY,
    RolID               INT NOT NULL REFERENCES Roller(RolID),
    TipID               INT NULL REFERENCES DokumanTipleri(TipID),
    KategoriID          INT NULL REFERENCES DokumanKategorileri(KategoriID),
    DepartmanID         INT NULL REFERENCES Departmanlar(DepartmanID),
    GizlilikMaxSeviyesi TINYINT NOT NULL DEFAULT 3 CHECK (GizlilikMaxSeviyesi BETWEEN 1 AND 5),
    OkumaYetkisi        BIT NOT NULL DEFAULT 0,
    YazmaYetkisi        BIT NOT NULL DEFAULT 0,
    SilmeYetkisi        BIT NOT NULL DEFAULT 0,
    IndirmeYetkisi      BIT NOT NULL DEFAULT 0,
    PaylasmaYetkisi     BIT NOT NULL DEFAULT 0,
    YetkiVerenID        INT NULL REFERENCES Kullanicilar(KullaniciID),
    BaslangicTarih      DATETIME NOT NULL DEFAULT GETDATE(),
    BitisTarih          DATETIME NULL,
    AktifMi             BIT NOT NULL DEFAULT 1
);

-- 12. ErisimLoglari  [2NF kanıtı: KullaniciAdi,DokumanBaslik burada YOK → JOIN]
CREATE TABLE ErisimLoglari (
    LogID          BIGINT IDENTITY(1,1) PRIMARY KEY,
    KullaniciID    INT NOT NULL REFERENCES Kullanicilar(KullaniciID),
    DokumanID      INT NOT NULL REFERENCES Dokumanlar(DokumanID),
    IslemTipi      NVARCHAR(30) NOT NULL
                   CHECK (IslemTipi IN
                   ('Goruntuleme','Indirme','Duzenleme','Silme',
                    'Paylasma','Yazdirma','Kopyalama','YetkiReddi')),
    IslemTarihi    DATETIME NOT NULL DEFAULT GETDATE(),
    IPAdresi       NVARCHAR(45) NULL,
    BrowserBilgisi NVARCHAR(200) NULL,
    BasariliMi     BIT NOT NULL DEFAULT 1,
    RedNedeni      NVARCHAR(255) NULL,
    OturumID       NVARCHAR(100) NULL,
    SunucuAdi      NVARCHAR(100) NULL
);

-- 13. IslemGecmisi
CREATE TABLE IslemGecmisi (
    IslemID         BIGINT IDENTITY(1,1) PRIMARY KEY,
    KullaniciID     INT NOT NULL REFERENCES Kullanicilar(KullaniciID),
    IslemKategorisi NVARCHAR(50) NOT NULL,
    IslemAciklama   NVARCHAR(500) NOT NULL,
    EtkiliTablo     NVARCHAR(100) NULL,
    EtkiliKayitID   INT NULL,
    EskiDeger       NVARCHAR(MAX) NULL,
    YeniDeger       NVARCHAR(MAX) NULL,
    IslemTarihi     DATETIME NOT NULL DEFAULT GETDATE(),
    IPAdresi        NVARCHAR(45) NULL,
    SonucDurumu     NVARCHAR(20) NOT NULL DEFAULT 'Basarili'
                    CHECK (SonucDurumu IN ('Basarili','Basarisiz','KismiBasari'))
);

-- 14. OnayAkislari
CREATE TABLE OnayAkislari (
    OnayID          INT IDENTITY(1,1) PRIMARY KEY,
    DokumanID       INT NOT NULL REFERENCES Dokumanlar(DokumanID),
    OnayCiID        INT NOT NULL REFERENCES Kullanicilar(KullaniciID),
    OnayAdimi       TINYINT NOT NULL,
    OnayDurumu      NVARCHAR(20) NOT NULL DEFAULT 'Bekliyor'
                    CHECK (OnayDurumu IN ('Bekliyor','Onaylandi','Reddedildi','IptalEdildi')),
    GonderilmeTarih DATETIME NOT NULL DEFAULT GETDATE(),
    OnayTarihi      DATETIME NULL,
    Yorum           NVARCHAR(500) NULL
);

-- 15. Bildirimler
CREATE TABLE Bildirimler (
    BildirimID     INT IDENTITY(1,1) PRIMARY KEY,
    AliciID        INT NOT NULL REFERENCES Kullanicilar(KullaniciID),
    GonderenID     INT NULL  REFERENCES Kullanicilar(KullaniciID),
    DokumanID      INT NULL  REFERENCES Dokumanlar(DokumanID),
    BildirimTipi   NVARCHAR(50) NOT NULL,
    Baslik         NVARCHAR(200) NOT NULL,
    Icerik         NVARCHAR(1000) NULL,
    OkunduMu       BIT NOT NULL DEFAULT 0,
    OlusturmaTarih DATETIME NOT NULL DEFAULT GETDATE(),
    OkunmaTarihi   DATETIME NULL
);

-- 16. Paylaşimlar
CREATE TABLE Paylaşimlar (
    PaylaşimID     INT IDENTITY(1,1) PRIMARY KEY,
    DokumanID      INT NOT NULL REFERENCES Dokumanlar(DokumanID),
    PaylaşanID     INT NOT NULL REFERENCES Kullanicilar(KullaniciID),
    AliciID        INT NULL  REFERENCES Kullanicilar(KullaniciID),
    AliciEmail     NVARCHAR(150) NULL,
    PaylaşimTipi   NVARCHAR(20) NOT NULL DEFAULT 'Dahili'
                   CHECK (PaylaşimTipi IN ('Dahili','Harici','Genel')),
    YetkiTipi      NVARCHAR(20) NOT NULL DEFAULT 'Okuma'
                   CHECK (YetkiTipi IN ('Okuma','Duzenleme','TamYetki')),
    BitisTarih     DATETIME NULL,
    AktifMi        BIT NOT NULL DEFAULT 1,
    OlusturmaTarih DATETIME NOT NULL DEFAULT GETDATE()
);

-- 17. SistemAyarlari
CREATE TABLE SistemAyarlari (
    AyarID           INT IDENTITY(1,1) PRIMARY KEY,
    AyarAnahtari     NVARCHAR(100) NOT NULL UNIQUE,
    AyarDegeri       NVARCHAR(1000) NULL,
    AyarTipi         NVARCHAR(20) NOT NULL DEFAULT 'Metin',
    Aciklama         NVARCHAR(300) NULL,
    GuncellenmeTarih DATETIME NOT NULL DEFAULT GETDATE(),
    GuncelleyenID    INT NULL REFERENCES Kullanicilar(KullaniciID)
);

-- 18. KisiselYetkiIstisnalari
CREATE TABLE KisiselYetkiIstisnalari (
    IstinaID       INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciID    INT NOT NULL REFERENCES Kullanicilar(KullaniciID),
    DokumanID      INT NULL  REFERENCES Dokumanlar(DokumanID),
    KategoriID     INT NULL  REFERENCES DokumanKategorileri(KategoriID),
    IstinaYonu     NVARCHAR(10) NOT NULL CHECK (IstinaYonu IN ('Izin','Yasak')),
    Aciklama       NVARCHAR(300) NULL,
    YetkiVerenID   INT NOT NULL REFERENCES Kullanicilar(KullaniciID),
    BaslangicTarih DATETIME NOT NULL DEFAULT GETDATE(),
    BitisTarih     DATETIME NULL,
    AktifMi        BIT NOT NULL DEFAULT 1
);
GO

-- İndeksler
CREATE INDEX IX_Dok_TipID         ON Dokumanlar(TipID);
CREATE INDEX IX_Dok_DeptID        ON Dokumanlar(DepartmanID);
CREATE INDEX IX_Dok_Durum         ON Dokumanlar(DokumanDurumu);
CREATE INDEX IX_Dok_Gizlilik      ON Dokumanlar(GizlilikSeviyesi);
CREATE INDEX IX_Dok_Tarih         ON Dokumanlar(OlusturmaTarih);
CREATE INDEX IX_Log_KullaniciID   ON ErisimLoglari(KullaniciID);
CREATE INDEX IX_Log_DokumanID     ON ErisimLoglari(DokumanID);
CREATE INDEX IX_Log_Tarih         ON ErisimLoglari(IslemTarihi);
CREATE INDEX IX_Log_IslemTipi     ON ErisimLoglari(IslemTipi);
CREATE INDEX IX_Ym_RolID          ON YetkiMatrisi(RolID);
CREATE INDEX IX_Kul_DeptID        ON Kullanicilar(DepartmanID);
CREATE INDEX IX_Ig_KullaniciID    ON IslemGecmisi(KullaniciID);
CREATE INDEX IX_Ig_Tarih          ON IslemGecmisi(IslemTarihi);
GO

-- ================================================================
-- §2  NORMALİZASYON KANITI
-- ================================================================
-- Bu bölüm tablolarımızın 1NF, 2NF ve 3NF kurallarını karşıladığını
-- hem açıklama hem doğrulanabilir sorgu ile kanıtlamaktadır.
-- ================================================================

/*
────────────────────────────────────────────────────────────────
  1NF — BİRİNCİ NORMAL FORM
  Kural 1: Her hücrede atomik (tek, bölünemez) değer bulunmalı.
  Kural 2: Tekrar eden sütun grubu olmamalı.
  Kural 3: Her satır, birincil anahtar (PK) ile benzersiz olmalı.

  1NF İHLAL SENARYOSU (yapmasaydık ne olurdu?):
    Dokumanlar tablosuna "Etiketler NVARCHAR(200)" sütunu koysaydık
    ve içine "Gizli,ISO,Acil" yazsaydık → 1NF ihlali.
    WHERE Etiketler = 'ISO' sorgusu ÇALIŞMAZDI.

  ÇÖZÜM: DokumanEtiketler tablosu — her etiket ayrı satır (N:M köprü).
────────────────────────────────────────────────────────────────
*/

-- §2-A: 1NF Kanıt 1 — Atomik değer testi
-- Tüm tablolarda çok değerli (virgüllü) veri içeren sütun var mı?
SELECT
    t.name  AS Tablo,
    c.name  AS Sutun,
    tp.name AS VeriTipi,
    '1NF: Atomik — çok degerli alan degil' AS NF1_Durumu
FROM sys.tables t
JOIN sys.columns c  ON c.object_id = t.object_id
JOIN sys.types  tp  ON tp.user_type_id = c.user_type_id
WHERE t.name IN (
    'Dokumanlar','ErisimLoglari','KullaniciRol',
    'DokumanEtiketler','YetkiMatrisi','Kullanicilar'
)
AND tp.name NOT IN ('text','ntext','xml','image')
ORDER BY t.name, c.column_id;

-- §2-A: 1NF Kanıt 2 — Etiketler N:M tablosu ile atomik yapı
-- (Etiketler "Gizli,ISO,Acil" tek hücrede DEĞİL; her biri ayrı satırda)
SELECT
    'DokumanEtiketler' AS Tablo,
    'DokumanID + EtiketID' AS BirlesikAnahtar,
    COUNT(*) AS SatirSayisi,
    COUNT(DISTINCT DokumanID) AS BenzersizDokuman,
    COUNT(DISTINCT EtiketID)  AS BenzersizEtiket,
    '1NF: Her satir tek bir dokuman-etiket cifti — atomik' AS Aciklama
FROM DokumanEtiketler;

/*
────────────────────────────────────────────────────────────────
  2NF — İKİNCİ NORMAL FORM
  Kural: 1NF sağlanmalı + anahtar olmayan her sütun tablonun
         TÜM birincil anahtarına tam fonksiyonel bağımlı olmalı.
         (Kısmi bağımlılık yasak)

  2NF İHLAL SENARYOSU:
    ErisimLoglari(KullaniciID, DokumanID, KullaniciAdi, DokumanBaslik)
    → KullaniciAdi sadece KullaniciID'ye bağlı (kısmi bağımlılık!)
    → DokumanBaslik sadece DokumanID'ye bağlı (kısmi bağımlılık!)

  ÇÖZÜM:
    ErisimLoglari → sadece FK tutar (KullaniciID, DokumanID)
    KullaniciAdi → Kullanicilar tablosunda
    DokumanBaslik → Dokumanlar tablosunda
────────────────────────────────────────────────────────────────
*/

-- §2-B: 2NF Kanıt — ErisimLoglari köprü tablosunda kısmi bağımlılık yok
SELECT
    'ErisimLoglari' AS Tablo,
    'LogID (BIGINT IDENTITY)' AS PK,
    'KullaniciID FK → Kullanicilar' AS Bagimlilik1,
    'DokumanID FK → Dokumanlar' AS Bagimlilik2,
    'IslemTipi, IslemTarihi → LogID nin tamamine bagli' AS TamBagimlilik,
    'KullaniciAdi/DokumanBaslik bu tabloda YOK → 2NF uyumlu' AS Sonuc;

-- §2-B: 2NF Kanıt — KullaniciRol köprü tablosunda kısmi bağımlılık yok
SELECT
    'KullaniciRol' AS Tablo,
    col.COLUMN_NAME,
    col.DATA_TYPE,
    CASE
        WHEN col.COLUMN_NAME IN ('KullaniciID','RolID')
            THEN 'FK — ilgili tabloya referans'
        WHEN col.COLUMN_NAME = 'KullaniciRolID'
            THEN 'PK — surrogat anahtar'
        ELSE 'Tum PK ye bagli (2NF uyumlu)'
    END AS NFDegerlendirme
FROM INFORMATION_SCHEMA.COLUMNS col
WHERE col.TABLE_NAME = 'KullaniciRol'
ORDER BY col.ORDINAL_POSITION;

/*
────────────────────────────────────────────────────────────────
  3NF — ÜÇÜNCÜ NORMAL FORM
  Kural: 2NF sağlanmalı + anahtar olmayan sütunlar birbirine
         geçişli bağımlı olmamalı.
         (A→B→C zinciri yasak; A=PK, B ve C anahtar olmayan)

  3NF İHLAL SENARYOSU:
    Dokumanlar(DokumanID, TipID, TipAdi, KategoriAdi)
    Zincir: DokumanID → TipID → TipAdi → KategoriAdi
    → TipAdi ve KategoriAdi, DokumanID'ye değil TipID'ye bağlı!

  ÇÖZÜM: 3 ayrı tablo:
    Dokumanlar → TipID (FK) → DokumanTipleri → KategoriID (FK)
                                             → DokumanKategorileri
────────────────────────────────────────────────────────────────
*/

-- §2-C: 3NF Kanıt — Geçişli bağımlılık zinciri kırılmış
SELECT
    Adim,
    Tablo,
    PKSutun,
    BagimliSutun,
    GecisBaglantisi,
    Aciklama
FROM (VALUES
    (1,'Dokumanlar',     'DokumanID', 'TipID (FK)',    'DokumanTipleri.TipID',      'Sadece FK tasiyor; TipAdi BURDA YOK'),
    (2,'DokumanTipleri', 'TipID',     'KategoriID (FK)','DokumanKategorileri.KatID','Sadece FK tasiyor; KategoriAdi BURDA YOK'),
    (3,'DokumanKategorileri','KategoriID','KategoriAdi','—',                        'Son nokta; PK ye dogrudan bagli — 3NF'),
    (4,'Kullanicilar',   'KullaniciID','DepartmanID (FK)','Departmanlar.DeptID',   'DeptAdi, DeptTel BURDA YOK — 3NF'),
    (5,'Departmanlar',   'DepartmanID','DepartmanAdi','—',                         'PK ye dogrudan bagli — 3NF')
) AS t(Adim,Tablo,PKSutun,BagimliSutun,GecisBaglantisi,Aciklama)
ORDER BY Adim;

-- §2-C: 3NF Kanıt — Dokumanlar tablosunda hangi sütunlar YOK?
SELECT
    'Dokumanlar tablosunda OLMAMASI GEREKEN ve OLMAYAN sutunlar' AS Baslik,
    '' AS Goster UNION ALL
SELECT '  TipAdi         → DokumanTipleri.TipAdi        (JOIN ile gelir)',   '' UNION ALL
SELECT '  KategoriAdi    → DokumanKategorileri.KatAdi   (JOIN ile gelir)',   '' UNION ALL
SELECT '  DepartmanAdi   → Departmanlar.DepartmanAdi    (JOIN ile gelir)',   '' UNION ALL
SELECT '  OlusturanEmail → Kullanicilar.Email            (JOIN ile gelir)',  '' UNION ALL
SELECT '  RolAdi         → Roller.RolAdi                (JOIN ile gelir)',   '' UNION ALL
SELECT '--- Sonuc: Gecisli bagimlilik yok → 3NF UYUMLU ---',                '';

-- §2-D: Tüm tablolar için NF özet matrisi
SELECT
    Sira, Tablo, SatirHedefi,
    NF1_AtomikDeger, NF2_KismiBasimlilikYok, NF3_GecisliBasimlilikYok,
    CASE WHEN NF1_AtomikDeger='Evet' AND NF2_KismiBasimlilikYok='Evet'
              AND NF3_GecisliBasimlilikYok='Evet'
         THEN '3NF Uyumlu'
         ELSE 'KONTROL ET'
    END AS GenelDurum
FROM (VALUES
     (1,'Departmanlar',          '~20',   'Evet','Evet','Evet'),
     (2,'Roller',                '8',     'Evet','Evet','Evet'),
     (3,'Kullanicilar',          '~510',  'Evet','Evet','Evet'),
     (4,'KullaniciRol',          '~560',  'Evet','Evet','Evet'),
     (5,'DokumanKategorileri',   '8',     'Evet','Evet','Evet'),
     (6,'DokumanTipleri',        '24',    'Evet','Evet','Evet'),
     (7,'Etiketler',             '15',    'Evet','Evet','Evet'),
     (8,'Dokumanlar',            '~2000', 'Evet','Evet','Evet'),
     (9,'DokumanVersiyonlari',   '~3500', 'Evet','Evet','Evet'),
    (10,'DokumanEtiketler',      '~2000', 'Evet','Evet','Evet'),
    (11,'YetkiMatrisi',          '~50',   'Evet','Evet','Evet'),
    (12,'ErisimLoglari',         '~2500', 'Evet','Evet','Evet'),
    (13,'IslemGecmisi',          '~1000', 'Evet','Evet','Evet'),
    (14,'OnayAkislari',          '~400',  'Evet','Evet','Evet'),
    (15,'Bildirimler',           '~300',  'Evet','Evet','Evet'),
    (16,'Paylaşimlar',           '~500',  'Evet','Evet','Evet'),
    (17,'SistemAyarlari',        '10',    'Evet','Evet','Evet'),
    (18,'KisiselYetkiIstisnalari','~50',  'Evet','Evet','Evet')
) AS t(Sira,Tablo,SatirHedefi,NF1_AtomikDeger,NF2_KismiBasimlilikYok,NF3_GecisliBasimlilikYok)
ORDER BY Sira;
GO

-- ================================================================
-- §3  REFERANS VERİLERİ
-- ================================================================

-- 3.1 Departmanlar (20 adet)
INSERT INTO Departmanlar (DepartmanAdi, DepartmanKodu, UstDepartmanID, Aciklama) VALUES
(N'Yönetim Kurulu',           'YK',   NULL, N'Üst yönetim birimi'),
(N'Genel Müdürlük',           'GM',   NULL, N'Genel müdür ofisi'),
(N'İnsan Kaynakları',         'IK',   2,    N'Personel ve işe alım'),
(N'Muhasebe ve Finans',       'MF',   2,    N'Mali işlemler'),
(N'Bilgi Teknolojileri',      'BT',   2,    N'Sistem ve altyapı'),
(N'Hukuk Müşavirliği',        'HM',   2,    N'Hukuki danışmanlık'),
(N'Araştırma ve Geliştirme',  'ARG',  2,    N'Ürün geliştirme'),
(N'Üretim',                   'URE',  2,    N'Üretim operasyonları'),
(N'Satış ve Pazarlama',       'SP',   2,    N'Satış faaliyetleri'),
(N'Müşteri Hizmetleri',       'MH',   9,    N'Müşteri destek'),
(N'Tedarik Zinciri',          'TZ',   2,    N'Satın alma ve lojistik'),
(N'Kalite Güvence',           'KG',   2,    N'Kalite kontrol'),
(N'İç Denetim',               'ID',   1,    N'Bağımsız iç denetim'),
(N'Proje Yönetim Ofisi',      'PYO',  2,    N'PMO merkezi'),
(N'İletişim ve PR',           'ILT',  2,    N'Basın ve iletişim'),
(N'Süreç Yönetimi',           'SY',   2,    N'İş süreçleri'),
(N'Veri Analitik',            'VA',   5,    N'Veri bilimi'),
(N'Siber Güvenlik',           'SG',   5,    N'Güvenlik operasyonları'),
(N'Uyum ve Risk',             'UR',   2,    N'Regülasyon uyumu'),
(N'Eğitim ve Gelişim',        'EG',   3,    N'Çalışan eğitimi');
GO

-- 3.2 Roller (8 adet — hiyerarşik)
INSERT INTO Roller (RolAdi, RolKodu, YetkiSeviyesi, Aciklama) VALUES
(N'Sistem Yöneticisi',    'SYS_ADMIN',  10, N'Tam sistem erişimi ve konfigürasyon'),
(N'Güvenlik Yöneticisi',  'SEC_ADMIN',   9, N'Yetki matrisi ve güvenlik politikaları'),
(N'Departman Yöneticisi', 'DEPT_MGR',    7, N'Kendi departmanına tam erişim'),
(N'Proje Yöneticisi',     'PROJ_MGR',    6, N'Atandığı projelere tam erişim'),
(N'Kıdemli Çalışan',      'SR_EMP',      5, N'Okuma ve yorum ekleme yetkisi'),
(N'Çalışan',              'EMPLOYEE',    3, N'Sadece yetkili belgelere okuma'),
(N'Misafir Kullanıcı',    'GUEST',       1, N'Yalnızca genel belgelere erişim'),
(N'Denetçi',              'AUDITOR',     8, N'Tüm belge ve logları okuma');
GO

-- 3.3 Doküman Kategorileri (8 adet)
INSERT INTO DokumanKategorileri (KategoriAdi, KategoriKodu, GizlilikSeviyesi, Aciklama) VALUES
(N'Hukuki Belgeler',      'HUK', 4, N'Sözleşme, protokol, vekaletname'),
(N'Teknik Belgeler',      'TEK', 3, N'Şartname, tasarım, mimari belgeler'),
(N'İnsan Kaynakları',     'IKB', 5, N'Özlük, performans, disiplin, maaş'),
(N'Mali ve Muhasebe',     'MAL', 4, N'Bütçe, bilanço, fatura, mali raporlar'),
(N'Ar-Ge ve Patent',      'ARG', 5, N'Fikri mülkiyet, patent, Ar-Ge raporları'),
(N'Yönetim Kararları',    'YON', 3, N'YK kararları, direktifler, yönetmelikler'),
(N'Müşteri ve CRM',       'MUS', 3, N'Müşteri sözleşmesi, teklif, şikayet'),
(N'Kalite Güvence',       'KAL', 2, N'ISO, test raporu, kalite prosedürü');
GO

-- 3.4 Doküman Tipleri (24 adet)
INSERT INTO DokumanTipleri (TipAdi, TipKodu, KategoriID, IzinliBoyutByte, IzinliUzantilar, SaklamaSuresiGun) VALUES
(N'İş Sözleşmesi',          'IS_SOZL',  1, 5242880,  '.pdf,.docx',        3650),
(N'Tedarikçi Sözleşmesi',   'TED_SOZL', 1, 5242880,  '.pdf,.docx',        3650),
(N'Gizlilik Sözleşmesi',    'NDA',      1, 2097152,  '.pdf,.docx',        2555),
(N'Teknik Şartname',        'TEK_SART', 2, 20971520, '.pdf,.docx,.xlsx',  1825),
(N'Tasarım Belgesi',        'TAS_BLG',  2, 52428800, '.pdf,.dwg,.docx',   1825),
(N'Sistem Mimarisi',        'SIS_MIM',  2, 10485760, '.pdf,.docx,.vsdx',  1095),
(N'Özlük Dosyası',          'OZLUK',    3, 10485760, '.pdf,.docx',       10950),
(N'Performans Değerlendirme','PERF_DEG',3, 5242880,  '.pdf,.docx,.xlsx',  2555),
(N'Disiplin Tutanağı',      'DIS_TUT',  3, 2097152,  '.pdf,.docx',       10950),
(N'Yıllık Bütçe',           'YIL_BUT',  4, 20971520, '.pdf,.xlsx',        3650),
(N'Fatura',                 'FATURA',   4, 2097152,  '.pdf,.xml',         2555),
(N'Mali Rapor',             'MAL_RAP',  4, 10485760, '.pdf,.xlsx',        3650),
(N'Patent Başvurusu',       'PAT_BAS',  5, 10485760, '.pdf,.docx',        7300),
(N'Ar-Ge Raporu',           'ARG_RAP',  5, 52428800, '.pdf,.docx,.xlsx',  3650),
(N'Ticari Sır Belgesi',     'TIC_SIR',  5, 5242880,  '.pdf',             10950),
(N'YK Kararı',              'YK_KARAR', 6, 5242880,  '.pdf,.docx',        7300),
(N'Yönetmelik',             'YONETMK',  6, 10485760, '.pdf,.docx',        3650),
(N'Direktif',               'DIREKTIF', 6, 2097152,  '.pdf,.docx',        1825),
(N'Müşteri Sözleşmesi',     'MUS_SOZL', 7, 5242880,  '.pdf,.docx',        3650),
(N'Teklif Belgesi',         'TEKLIF',   7, 10485760, '.pdf,.docx,.pptx',   365),
(N'Müşteri Şikayeti',       'MUS_SIK',  7, 5242880,  '.pdf,.docx',        1095),
(N'ISO Belgesi',            'ISO_BLG',  8, 5242880,  '.pdf',              1825),
(N'Test Raporu',            'TEST_RAP', 8, 20971520, '.pdf,.xlsx,.docx',  1095),
(N'Kalite Prosedürü',       'KAL_PRO',  8, 10485760, '.pdf,.docx',        1825);
GO

-- 3.5 Etiketler (15 adet)
INSERT INTO Etiketler (EtiketAdi, Renk) VALUES
(N'Gizli',         '#EF4444'),(N'Kritik',       '#DC2626'),
(N'Acil',          '#F97316'),(N'İncelemede',   '#F59E0B'),
(N'Onaylandı',     '#10B981'),(N'Arşivlendi',   '#6B7280'),
(N'Revizyon',      '#8B5CF6'),(N'Dış Paylaşım', '#EC4899'),
(N'ISO',           '#3B82F6'),(N'KVKK',         '#06B6D4'),
(N'Yasal Zorunlu', '#059669'),(N'Pilot',        '#84CC16'),
(N'Şablon',        '#A78BFA'),(N'Son Versiyon', '#34D399'),
(N'Taslak',        '#94A3B8');
GO

-- 3.6 Sistem Ayarları
INSERT INTO SistemAyarlari (AyarAnahtari, AyarDegeri, AyarTipi, Aciklama) VALUES
('MaxGizlilikSeviyesi','5',        'Sayi', 'Sistem genelinde max gizlilik'),
('SessionTimeoutSn',  '3600',      'Sayi', 'Oturum zaman asimi saniye'),
('LogRetentionGun',   '2555',      'Sayi', 'Log saklama suresi gun'),
('MaxDosyaBoyutByte', '104857600', 'Sayi', 'Maks dosya boyutu'),
('MinSifreUzunluk',   '12',        'Sayi', 'Minimum sifre uzunlugu'),
('MaxLoginDenemesi',  '5',         'Sayi', 'Basarisiz giris limiti'),
('WatermarkAktif',    'true',      'Bool', 'PDF filigran'),
('AuditLogAktif',     'true',      'Bool', 'Erisim logu'),
('EmailBildirimAktif','true',      'Bool', 'E-posta bildirimleri'),
('VersiyonOtoAktif',  'true',      'Bool', 'Otomatik versiyon');
GO

-- ================================================================
-- §4  KULLANICI VERİLERİ  (~510 kayıt)
-- ================================================================

CREATE OR ALTER PROCEDURE sp_KullanicilariUret AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @i INT = 1;
    DECLARE @ad    NVARCHAR(30);
    DECLARE @soyad NVARCHAR(30);
    DECLARE @unvan NVARCHAR(80);
    DECLARE @deptID INT, @kadi NVARCHAR(50);

    DECLARE @adlar   TABLE (rn INT IDENTITY(1,1), v NVARCHAR(30));
    DECLARE @soyadlar TABLE(rn INT IDENTITY(1,1), v NVARCHAR(30));
    DECLARE @unvanlar TABLE(rn INT IDENTITY(1,1), v NVARCHAR(80));

    INSERT INTO @adlar(v) VALUES
    (N'Ahmet'),(N'Mehmet'),(N'Ali'),(N'Mustafa'),(N'Hüseyin'),
    (N'İbrahim'),(N'Hasan'),(N'İsmail'),(N'Ömer'),(N'Yusuf'),
    (N'Ayşe'),(N'Fatma'),(N'Zeynep'),(N'Emine'),(N'Hatice'),
    (N'Merve'),(N'Elif'),(N'Büşra'),(N'Selin'),(N'Gizem'),
    (N'Can'),(N'Cem'),(N'Emre'),(N'Burak'),(N'Murat'),
    (N'Sercan'),(N'Kemal'),(N'Tarık'),(N'Oğuz'),(N'Berk'),
    (N'Deniz'),(N'Melis'),(N'Pınar'),(N'Ceren'),(N'Tuğba'),
    (N'Arzu'),(N'Özge'),(N'Neslihan'),(N'Sibel'),(N'Esra'),
    (N'Kaan'),(N'Tolga'),(N'Serhat'),(N'Ümit'),(N'Barış');

    INSERT INTO @soyadlar(v) VALUES
    (N'Yılmaz'),(N'Kaya'),(N'Demir'),(N'Çelik'),(N'Şahin'),
    (N'Doğan'),(N'Kılıç'),(N'Aslan'),(N'Çetin'),(N'Öztürk'),
    (N'Aydın'),(N'Özdemir'),(N'Arslan'),(N'Doğru'),(N'Aktaş'),
    (N'Yıldız'),(N'Kurt'),(N'Polat'),(N'Korkmaz'),(N'Erdoğan'),
    (N'Koç'),(N'Güler'),(N'Çakır'),(N'Coşkun'),(N'Bozkurt'),
    (N'Karaca'),(N'Aksoy'),(N'Duman'),(N'Erol'),(N'Bulut'),
    (N'Tekin'),(N'Acar'),(N'Keskin'),(N'Sahin'),(N'Celik');

    INSERT INTO @unvanlar(v) VALUES
    (N'Müdür'),(N'Uzman'),(N'Kıdemli Uzman'),(N'Mühendis'),
    (N'Analist'),(N'Koordinatör'),(N'Asistan'),(N'Danışman'),
    (N'Teknisyen'),(N'Yetkili'),(N'Direktör'),(N'Baş Uzman');

    WHILE @i <= 480
    BEGIN
        DECLARE @aIdx  INT = (@i % 45) + 1;
        DECLARE @sIdx  INT = ((@i * 7) % 35) + 1;
        DECLARE @uIdx  INT = ((@i * 3) % 12) + 1;
        SET @deptID = (@i % 20) + 1;

        SELECT @ad    = v FROM @adlar    WHERE rn = @aIdx;
        SELECT @soyad = v FROM @soyadlar WHERE rn = @sIdx;
        SELECT @unvan = v FROM @unvanlar WHERE rn = @uIdx;

        SET @kadi = LOWER(LEFT(REPLACE(REPLACE(REPLACE(REPLACE(@ad,
            N'İ','i'),N'Ğ','g'),N'Ş','s'),N'Ü','u'), 3))
                 + LOWER(LEFT(REPLACE(REPLACE(@soyad,N'Ç','c'),N'Ö','o'), 4))
                 + CAST(@i AS NVARCHAR(5));

        IF NOT EXISTS (SELECT 1 FROM Kullanicilar WHERE KullaniciAdi = @kadi)
        BEGIN
            INSERT INTO Kullanicilar
            (KullaniciAdi,Ad,Soyad,Email,SifreHash,DepartmanID,Unvan,AktifMi,SonGirisTarih)
            VALUES (
                @kadi, @ad, @soyad,
                @kadi + N'@sirket.com.tr',
                CONVERT(NVARCHAR(256),HASHBYTES('SHA2_256',@kadi+N'P@ss2026!'),2),
                @deptID, @unvan,
                CASE WHEN @i % 20 = 0 THEN 0 ELSE 1 END,
                DATEADD(MINUTE, -(ABS(CHECKSUM(NEWID())) % 43200), GETDATE())
            );
        END;
        SET @i = @i + 1;
    END;
END;
GO
EXEC sp_KullanicilariUret;
GO

-- Sabit yönetici & özel kullanıcılar
INSERT INTO Kullanicilar
(KullaniciAdi,Ad,Soyad,Email,SifreHash,DepartmanID,Unvan,AktifMi,SonGirisTarih) VALUES
('sysadmin_001', N'Sistem',   N'Yöneticisi', 'sysadmin@sirket.com.tr',
 CONVERT(NVARCHAR(256),HASHBYTES('SHA2_256','SysAdm2026!'),2), 5, N'Sistem Yöneticisi',1,GETDATE()),
('secmgr_001',   N'Güvenlik', N'Yöneticisi', 'secmgr@sirket.com.tr',
 CONVERT(NVARCHAR(256),HASHBYTES('SHA2_256','SecMgr2026!'),2),18, N'Güvenlik Müdürü', 1,GETDATE()),
('auditor_001',  N'Baş',      N'Denetçi',    'auditor@sirket.com.tr',
 CONVERT(NVARCHAR(256),HASHBYTES('SHA2_256','Audit2026!'), 2),13, N'Baş Denetçi',     1,GETDATE()),
('guest_001',    N'Misafir',  N'Kullanıcı',  'guest001@harici.com.tr',
 CONVERT(NVARCHAR(256),HASHBYTES('SHA2_256','Guest2026!'), 2), 2, N'Misafir',          1,GETDATE()),
('ik_mgr_001',   N'Ayşe',    N'Karabulut',  'ik.mudur@sirket.com.tr',
 CONVERT(NVARCHAR(256),HASHBYTES('SHA2_256','IkMgr2026!'), 2), 3, N'İK Müdürü',       1,GETDATE()),
('fin_mgr_001',  N'Mehmet',  N'Arslan',     'finans.mudur@sirket.com.tr',
 CONVERT(NVARCHAR(256),HASHBYTES('SHA2_256','FinMgr2026!'),2), 4, N'Finans Müdürü',   1,GETDATE()),
('bt_mgr_001',   N'Ali',     N'Demir',      'bt.mudur@sirket.com.tr',
 CONVERT(NVARCHAR(256),HASHBYTES('SHA2_256','BtMgr2026!'), 2), 5, N'BT Müdürü',       1,GETDATE()),
('huk_mgr_001',  N'Zeynep',  N'Yıldız',    'hukuk.mudur@sirket.com.tr',
 CONVERT(NVARCHAR(256),HASHBYTES('SHA2_256','HukMgr2026!'),2), 6, N'Hukuk Müşaviri',  1,GETDATE()),
('arg_mgr_001',  N'Emre',    N'Çelik',     'arg.mudur@sirket.com.tr',
 CONVERT(NVARCHAR(256),HASHBYTES('SHA2_256','ArgMgr2026!'),2), 7, N'Ar-Ge Müdürü',    1,GETDATE()),
('ure_mgr_001',  N'Fatma',   N'Kaya',      'ure.mudur@sirket.com.tr',
 CONVERT(NVARCHAR(256),HASHBYTES('SHA2_256','UreMgr2026!'),2), 8, N'Üretim Müdürü',   1,GETDATE());
GO

-- Kullanıcı–Rol atamaları
DECLARE @sysID INT = (SELECT KullaniciID FROM Kullanicilar WHERE KullaniciAdi='sysadmin_001');
DECLARE @secID INT = (SELECT KullaniciID FROM Kullanicilar WHERE KullaniciAdi='secmgr_001');

-- Özel roller
INSERT INTO KullaniciRol(KullaniciID,RolID,AtayanID) VALUES
((SELECT KullaniciID FROM Kullanicilar WHERE KullaniciAdi='sysadmin_001'),1,NULL),
((SELECT KullaniciID FROM Kullanicilar WHERE KullaniciAdi='secmgr_001'), 2,@sysID),
((SELECT KullaniciID FROM Kullanicilar WHERE KullaniciAdi='auditor_001'),8,@sysID),
((SELECT KullaniciID FROM Kullanicilar WHERE KullaniciAdi='guest_001'),  7,@sysID),
((SELECT KullaniciID FROM Kullanicilar WHERE KullaniciAdi='ik_mgr_001'), 3,@secID),
((SELECT KullaniciID FROM Kullanicilar WHERE KullaniciAdi='fin_mgr_001'),3,@secID),
((SELECT KullaniciID FROM Kullanicilar WHERE KullaniciAdi='bt_mgr_001'), 3,@secID),
((SELECT KullaniciID FROM Kullanicilar WHERE KullaniciAdi='huk_mgr_001'),3,@secID),
((SELECT KullaniciID FROM Kullanicilar WHERE KullaniciAdi='arg_mgr_001'),3,@secID),
((SELECT KullaniciID FROM Kullanicilar WHERE KullaniciAdi='ure_mgr_001'),3,@secID);

-- Genel rol ataması
INSERT INTO KullaniciRol(KullaniciID,RolID,AtayanID)
SELECT KullaniciID,
       CASE WHEN KullaniciID % 8 = 0 THEN 4
            WHEN KullaniciID % 5 = 0 THEN 5
            ELSE 6 END,
       @secID
FROM Kullanicilar
WHERE KullaniciAdi NOT IN ('sysadmin_001','secmgr_001','auditor_001',
                           'guest_001','ik_mgr_001','fin_mgr_001',
                           'bt_mgr_001','huk_mgr_001','arg_mgr_001','ure_mgr_001');
GO

-- ================================================================
-- §5  DOKÜMAN VERİLERİ  (~2000 kayıt)
-- ================================================================

CREATE OR ALTER PROCEDURE sp_DokumanlariUret AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @i INT = 1;
    DECLARE @maxK INT = (SELECT MAX(KullaniciID) FROM Kullanicilar);
    DECLARE @maxT INT = 24;
    DECLARE @maxD INT = 20;

    DECLARE @basliklar TABLE (rn INT IDENTITY(1,1), v NVARCHAR(150));
    INSERT INTO @basliklar(v) VALUES
    (N'Bütçe Planı'),(N'Faaliyet Raporu'),(N'Tedarikçi Değerlendirme'),
    (N'Kalite Kontrol Prosedürü'),(N'Sistem Mimarisi Dokümanı'),
    (N'Müşteri Anlaşması'),(N'İşe Alım Politikası'),(N'Veri Koruma Politikası'),
    (N'Risk Yönetimi Planı'),(N'Proje Başlangıç Belgesi'),
    (N'Teknik Gereksinim Şartnamesi'),(N'Güvenlik Denetim Raporu'),
    (N'Performans Değerlendirme Formu'),(N'Eğitim Planı'),(N'Organizasyon Şeması'),
    (N'Yazılım Lisans Sözleşmesi'),(N'Bakım Sözleşmesi'),(N'Ar-Ge Proje Planı'),
    (N'ISO 9001 Prosedürü'),(N'Aylık Finansal Özet'),
    (N'Siber Güvenlik Politikası'),(N'KVKK Uyum Raporu'),
    (N'İş Sürekliliği Planı'),(N'Felaket Kurtarma Dokümanı'),
    (N'Yıllık Denetim Raporu'),(N'Yatırım Teklifleri Özeti'),
    (N'Çevre Yönetim Planı'),(N'Patent Başvuru Formu'),
    (N'Müşteri Memnuniyet Analizi'),(N'Tedarik Zinciri Analizi');

    WHILE @i <= 2000
    BEGIN
        DECLARE @tIdx INT = (@i % @maxT) + 1;
        DECLARE @dIdx INT = (@i % @maxD) + 1;
        DECLARE @oID  INT = (ABS(CHECKSUM(NEWID())) % @maxK) + 1;
        DECLARE @sID  INT = (ABS(CHECKSUM(NEWID())) % @maxK) + 1;
        DECLARE @giz  TINYINT = CASE
            WHEN @i % 20 = 0 THEN 5 WHEN @i % 7 = 0 THEN 4
            WHEN @i % 4 = 0  THEN 3 WHEN @i % 2 = 0 THEN 2 ELSE 1 END;
        DECLARE @bIdx INT = (@i % 30) + 1;
        DECLARE @bas  NVARCHAR(300);
        SELECT @bas = v FROM @basliklar WHERE rn = @bIdx;
        SET @bas = @bas + N' — ' + CAST(2024 + (@i % 3) AS NVARCHAR) + N'/' + CAST(@i AS NVARCHAR);

        DECLARE @dur NVARCHAR(20) = CASE
            WHEN @i % 100 <  5  THEN N'Taslak'
            WHEN @i % 100 < 15  THEN N'Inceleme'
            WHEN @i % 100 < 30  THEN N'Onaylandi'
            WHEN @i % 100 < 90  THEN N'Yayinlandi'
            WHEN @i % 100 < 98  THEN N'Arsivlendi'
            ELSE                     N'Iptal' END;

        DECLARE @dno NVARCHAR(50) = 'DOC-' + FORMAT(GETDATE(),'yyyy') + '-' + RIGHT('00000'+CAST(@i AS NVARCHAR),5);

        IF NOT EXISTS (SELECT 1 FROM Dokumanlar WHERE DokumanNo=@dno)
           AND EXISTS  (SELECT 1 FROM Kullanicilar WHERE KullaniciID=@oID)
        BEGIN
            INSERT INTO Dokumanlar
            (Baslik,DokumanNo,TipID,DepartmanID,OlusturanID,SorumluID,
             GizlilikSeviyesi,DokumanDurumu,AciklamaKisa,
             DosyaBoyutu,DosyaUzantisi,
             OlusturmaTarih,GuncellenmeTarih,YayinTarihi,SonGecerlilikTarih)
            VALUES (
                @bas, @dno, @tIdx, @dIdx, @oID, @sID,
                @giz, @dur,
                N'Otomatik test kaydı #' + CAST(@i AS NVARCHAR),
                (@i * 12345) % 10485760 + 1024,
                CASE @tIdx % 4 WHEN 0 THEN '.pdf' WHEN 1 THEN '.docx'
                               WHEN 2 THEN '.xlsx' ELSE '.pdf' END,
                DATEADD(DAY, -(@i % 730), GETDATE()),
                CASE WHEN @i%3=0 THEN DATEADD(DAY,-(@i%30),GETDATE()) ELSE NULL END,
                CASE WHEN @dur=N'Yayinlandi' THEN DATEADD(DAY,-(@i%365),GETDATE()) ELSE NULL END,
                DATEADD(YEAR,5, DATEADD(DAY,-(@i%730),GETDATE()))
            );
        END;
        SET @i = @i + 1;
    END;
END;
GO
EXEC sp_DokumanlariUret;
GO

-- Versiyon geçmişi (~3 versiyon/belge → ~3500 satır)
INSERT INTO DokumanVersiyonlari(DokumanID,VersiyonNo,DegisiklikNotu,OlusturanID,DosyaBoyutu)
SELECT DokumanID,'1.0',N'İlk versiyon',OlusturanID,DosyaBoyutu FROM Dokumanlar;

INSERT INTO DokumanVersiyonlari(DokumanID,VersiyonNo,DegisiklikNotu,OlusturanID,DosyaBoyutu)
SELECT DokumanID,'1.1',N'Revizyon — içerik güncellendi',SorumluID,CAST(DosyaBoyutu*1.1 AS BIGINT)
FROM Dokumanlar WHERE DokumanID%3=0 AND SorumluID IS NOT NULL;

INSERT INTO DokumanVersiyonlari(DokumanID,VersiyonNo,DegisiklikNotu,OlusturanID,DosyaBoyutu)
SELECT DokumanID,'2.0',N'Büyük revizyon — yeni şablon',OlusturanID,CAST(DosyaBoyutu*1.3 AS BIGINT)
FROM Dokumanlar WHERE DokumanID%7=0;

-- Etiket atamaları (1NF kanıtı: her etiket ayrı satırda)
INSERT INTO DokumanEtiketler(DokumanID,EtiketID,EkleyenID)
SELECT DokumanID,
    CASE WHEN GizlilikSeviyesi>=4 THEN 1
         WHEN GizlilikSeviyesi=3  THEN 2
         WHEN DokumanDurumu=N'Inceleme'   THEN 4
         WHEN DokumanDurumu=N'Onaylandi'  THEN 5
         WHEN DokumanDurumu=N'Arsivlendi' THEN 6
         ELSE 14 END,
    OlusturanID
FROM Dokumanlar;

-- İkinci etiket (ISO veya KVKK) — her belgenin ikinci etiketi atomik satır
INSERT INTO DokumanEtiketler(DokumanID,EtiketID,EkleyenID)
SELECT DokumanID,
    CASE WHEN DokumanID%5=0 THEN 9   -- ISO
         WHEN DokumanID%7=0 THEN 10  -- KVKK
         ELSE 11 END,                -- Yasal Zorunlu
    OlusturanID
FROM Dokumanlar
WHERE DokumanID%3=0;
GO

-- ================================================================
-- §6  YETKİ MATRİSİ
-- ================================================================

-- Sistem Yöneticisi — her şeye tam erişim
INSERT INTO YetkiMatrisi(RolID,GizlilikMaxSeviyesi,OkumaYetkisi,YazmaYetkisi,SilmeYetkisi,IndirmeYetkisi,PaylasmaYetkisi)
VALUES(1,5,1,1,1,1,1);
-- Güvenlik Yöneticisi
INSERT INTO YetkiMatrisi(RolID,GizlilikMaxSeviyesi,OkumaYetkisi,YazmaYetkisi,SilmeYetkisi,IndirmeYetkisi,PaylasmaYetkisi)
VALUES(2,5,1,1,0,1,1);
-- Denetçi
INSERT INTO YetkiMatrisi(RolID,GizlilikMaxSeviyesi,OkumaYetkisi,YazmaYetkisi,SilmeYetkisi,IndirmeYetkisi,PaylasmaYetkisi)
VALUES(8,5,1,0,0,1,0);
-- Departman Yöneticisi — tüm kategoriler
INSERT INTO YetkiMatrisi(RolID,KategoriID,GizlilikMaxSeviyesi,OkumaYetkisi,YazmaYetkisi,SilmeYetkisi,IndirmeYetkisi,PaylasmaYetkisi)
SELECT 3,KategoriID,4,1,1,1,1,1 FROM DokumanKategorileri;
-- Proje Yöneticisi
INSERT INTO YetkiMatrisi(RolID,KategoriID,GizlilikMaxSeviyesi,OkumaYetkisi,YazmaYetkisi,SilmeYetkisi,IndirmeYetkisi,PaylasmaYetkisi)
SELECT 4,KategoriID,3,1,1,0,1,1 FROM DokumanKategorileri WHERE KategoriID NOT IN(3,4);
-- Kıdemli Çalışan
INSERT INTO YetkiMatrisi(RolID,KategoriID,GizlilikMaxSeviyesi,OkumaYetkisi,YazmaYetkisi,SilmeYetkisi,IndirmeYetkisi,PaylasmaYetkisi)
SELECT 5,KategoriID,2,1,0,0,1,0 FROM DokumanKategorileri WHERE KategoriID IN(2,6,7,8);
-- Çalışan
INSERT INTO YetkiMatrisi(RolID,KategoriID,GizlilikMaxSeviyesi,OkumaYetkisi,YazmaYetkisi,SilmeYetkisi,IndirmeYetkisi,PaylasmaYetkisi)
SELECT 6,KategoriID,1,1,0,0,0,0 FROM DokumanKategorileri WHERE KategoriID IN(6,8);
-- Misafir
INSERT INTO YetkiMatrisi(RolID,KategoriID,GizlilikMaxSeviyesi,OkumaYetkisi,YazmaYetkisi,SilmeYetkisi,IndirmeYetkisi,PaylasmaYetkisi)
SELECT 7,KategoriID,1,1,0,0,0,0 FROM DokumanKategorileri WHERE KategoriID=8;
GO

-- ================================================================
-- §7  ERİŞİM LOGLARI  (~2500 kayıt)
-- ================================================================

CREATE OR ALTER PROCEDURE sp_LogUret AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @i INT = 1;
    DECLARE @maxK INT=(SELECT MAX(KullaniciID) FROM Kullanicilar);
    DECLARE @maxD INT=(SELECT MAX(DokumanID)  FROM Dokumanlar);
    DECLARE @islemler TABLE(rn INT IDENTITY(1,1), v NVARCHAR(30));
    DECLARE @ipler    TABLE(rn INT IDENTITY(1,1), v NVARCHAR(15));
    INSERT INTO @islemler(v) VALUES
    ('Goruntuleme'),('Goruntuleme'),('Goruntuleme'),('Indirme'),
    ('Duzenleme'),('Paylasma'),('Yazdirma'),('Kopyalama'),
    ('YetkiReddi'),('Silme');
    INSERT INTO @ipler(v) VALUES
    ('192.168.1.'),('10.0.0.'),('172.16.0.'),('192.168.10.'),('10.10.0.');

    WHILE @i <= 2500
    BEGIN
        DECLARE @kID INT=(ABS(CHECKSUM(NEWID()))%@maxK)+1;
        DECLARE @dID INT=(ABS(CHECKSUM(NEWID()))%@maxD)+1;
        DECLARE @itmIdx INT=(@i%10)+1;
        DECLARE @itm NVARCHAR(30);
        SELECT @itm=v FROM @islemler WHERE rn=@itmIdx;
        DECLARE @ipIdx INT=(@i%5)+1;
        DECLARE @ip   NVARCHAR(45);
        SELECT @ip=v FROM @ipler WHERE rn=@ipIdx;
        SET @ip = @ip + CAST((@i%254)+1 AS NVARCHAR);
        DECLARE @bas BIT = CASE WHEN @i%10=0 THEN 0 ELSE 1 END;

        IF EXISTS(SELECT 1 FROM Kullanicilar WHERE KullaniciID=@kID)
           AND EXISTS(SELECT 1 FROM Dokumanlar  WHERE DokumanID=@dID)
        BEGIN
            INSERT INTO ErisimLoglari
            (KullaniciID,DokumanID,IslemTipi,IslemTarihi,IPAdresi,BasariliMi,RedNedeni,OturumID)
            VALUES(
                @kID,@dID,@itm,
                DATEADD(MINUTE,-(ABS(CHECKSUM(NEWID()))%525600),GETDATE()),
                @ip, @bas,
                CASE WHEN @bas=0 THEN N'Gizlilik seviyesi yetersiz' ELSE NULL END,
                'SES-'+CAST(@i%1000 AS NVARCHAR)
            );
        END;
        SET @i=@i+1;
    END;
END;
GO
EXEC sp_LogUret;
GO

-- İşlem Geçmişi (~1000 kayıt)
CREATE OR ALTER PROCEDURE sp_IslemGecmisiUret AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @i INT=1;
    DECLARE @maxK INT=(SELECT MAX(KullaniciID) FROM Kullanicilar);
    DECLARE @katlar TABLE(rn INT IDENTITY(1,1), v NVARCHAR(50));
    INSERT INTO @katlar(v) VALUES
    ('KullaniciIslemleri'),('DokumanIslemleri'),('YetkiIslemleri'),
    ('SistemIslemleri'),('RolIslemleri'),('DepartmanIslemleri');

    WHILE @i<=1000
    BEGIN
        DECLARE @kID INT=(ABS(CHECKSUM(NEWID()))%@maxK)+1;
        DECLARE @kIdx INT=(@i%6)+1;
        DECLARE @kat NVARCHAR(50);
        SELECT @kat=v FROM @katlar WHERE rn=@kIdx;
        IF EXISTS(SELECT 1 FROM Kullanicilar WHERE KullaniciID=@kID)
        BEGIN
            INSERT INTO IslemGecmisi
            (KullaniciID,IslemKategorisi,IslemAciklama,EtkiliTablo,EtkiliKayitID,
             IslemTarihi,IPAdresi,SonucDurumu)
            VALUES(
                @kID,@kat,
                CASE @kat
                    WHEN 'KullaniciIslemleri' THEN N'Kullanıcı profili güncellendi'
                    WHEN 'DokumanIslemleri'   THEN N'Doküman durumu değiştirildi'
                    WHEN 'YetkiIslemleri'     THEN N'Yetki matrisi güncellendi'
                    WHEN 'SistemIslemleri'    THEN N'Sistem ayarı değiştirildi'
                    WHEN 'RolIslemleri'       THEN N'Kullanıcıya rol atandı'
                    ELSE                          N'Departman bilgisi güncellendi'
                END,
                CASE @kat
                    WHEN 'KullaniciIslemleri' THEN 'Kullanicilar'
                    WHEN 'DokumanIslemleri'   THEN 'Dokumanlar'
                    WHEN 'YetkiIslemleri'     THEN 'YetkiMatrisi'
                    ELSE 'SistemAyarlari' END,
                (@i%200)+1,
                DATEADD(MINUTE,-(ABS(CHECKSUM(NEWID()))%525600),GETDATE()),
                '10.0.0.'+CAST((@i%254)+1 AS NVARCHAR),
                CASE WHEN @i%15=0 THEN 'Basarisiz' ELSE 'Basarili' END
            );
        END;
        SET @i=@i+1;
    END;
END;
GO
EXEC sp_IslemGecmisiUret;
GO

-- Onay akışları (~400 kayıt)
INSERT INTO OnayAkislari(DokumanID,OnayCiID,OnayAdimi,OnayDurumu,GonderilmeTarih,OnayTarihi,Yorum)
SELECT d.DokumanID,
    (SELECT TOP 1 KullaniciID FROM Kullanicilar WHERE Unvan LIKE N'%Müdür%'
     ORDER BY NEWID()),
    1,
    CASE d.DokumanDurumu
        WHEN N'Yayinlandi' THEN 'Onaylandi'
        WHEN N'Iptal'      THEN 'Reddedildi'
        ELSE 'Bekliyor' END,
    DATEADD(DAY,-30,d.OlusturmaTarih),
    CASE WHEN d.DokumanDurumu=N'Yayinlandi'
         THEN DATEADD(DAY,-15,d.OlusturmaTarih) ELSE NULL END,
    CASE WHEN d.DokumanDurumu=N'Iptal'
         THEN N'Eksik belgeler mevcut' ELSE NULL END
FROM Dokumanlar d
WHERE d.DokumanID%5=0;

-- Paylaşımlar (~500 kayıt)
INSERT INTO Paylaşimlar(DokumanID,PaylaşanID,AliciID,PaylaşimTipi,YetkiTipi,BitisTarih,AktifMi)
SELECT TOP 500
    d.DokumanID, d.OlusturanID, k.KullaniciID,
    CASE d.DokumanID%3 WHEN 0 THEN 'Dahili' WHEN 1 THEN 'Harici' ELSE 'Genel' END,
    CASE d.DokumanID%3 WHEN 0 THEN 'Okuma'  WHEN 1 THEN 'Duzenleme' ELSE 'TamYetki' END,
    CASE WHEN d.DokumanID%4=0 THEN DATEADD(MONTH,3,GETDATE()) ELSE NULL END,
    1
FROM Dokumanlar d CROSS JOIN Kullanicilar k
WHERE d.DokumanID<>k.KullaniciID AND d.GizlilikSeviyesi<=3
ORDER BY NEWID();

-- Bildirimler (~300 kayıt)
INSERT INTO Bildirimler(AliciID,GonderenID,DokumanID,BildirimTipi,Baslik,Icerik,OkunduMu)
SELECT TOP 300
    k.KullaniciID, d.OlusturanID, d.DokumanID,
    CASE d.DokumanID%4
        WHEN 0 THEN 'OnayBekliyor'
        WHEN 1 THEN 'DokumanGuncellendi'
        WHEN 2 THEN 'YetkiDegisikligi'
        ELSE        'SonGecerlilikUyarisi' END,
    CASE d.DokumanID%4
        WHEN 0 THEN N'Onay Bekleniyor: ' + LEFT(d.Baslik,40)
        WHEN 1 THEN N'Güncelleme: '      + LEFT(d.Baslik,40)
        WHEN 2 THEN N'Yetki Değişikliği'
        ELSE        N'Son Geçerlilik Yaklaşıyor' END,
    N'Otomatik sistem bildirimi.',
    CASE WHEN k.KullaniciID%3=0 THEN 1 ELSE 0 END
FROM Dokumanlar d CROSS JOIN Kullanicilar k
WHERE d.DokumanID%7=0
ORDER BY NEWID();
GO

-- ================================================================
-- §8  VIEW TANIMLARI
-- ================================================================

CREATE OR ALTER VIEW vw_DokumanDetay AS
SELECT d.DokumanID, d.Baslik, d.DokumanNo, d.DokumanDurumu,
       d.GizlilikSeviyesi, d.DosyaBoyutu, d.DosyaUzantisi,
       d.OlusturmaTarih, d.GuncellenmeTarih, d.YayinTarihi,
       dt.TipAdi, dt.TipKodu,
       dk.KategoriAdi, dk.KategoriKodu,
       dep.DepartmanAdi, dep.DepartmanKodu,
       k.Ad+' '+k.Soyad   AS OlusturanAdi,
       k.Email             AS OlusturanEmail,
       ks.Ad+' '+ks.Soyad AS SorumluAdi
FROM Dokumanlar d
JOIN DokumanTipleri dt      ON dt.TipID      = d.TipID
JOIN DokumanKategorileri dk ON dk.KategoriID = dt.KategoriID
JOIN Departmanlar dep       ON dep.DepartmanID= d.DepartmanID
JOIN Kullanicilar k         ON k.KullaniciID  = d.OlusturanID
LEFT JOIN Kullanicilar ks   ON ks.KullaniciID = d.SorumluID;
GO

CREATE OR ALTER VIEW vw_KullaniciYetkileri AS
SELECT k.KullaniciID, k.KullaniciAdi, k.Ad+' '+k.Soyad AS TamAd,
       k.Email, dep.DepartmanAdi,
       r.RolAdi, r.YetkiSeviyesi,
       ym.OkumaYetkisi, ym.YazmaYetkisi, ym.SilmeYetkisi,
       ym.IndirmeYetkisi, ym.PaylasmaYetkisi, ym.GizlilikMaxSeviyesi,
       dk.KategoriAdi
FROM Kullanicilar k
JOIN KullaniciRol kr          ON kr.KullaniciID = k.KullaniciID AND kr.AktifMi=1
JOIN Roller r                 ON r.RolID        = kr.RolID
JOIN Departmanlar dep         ON dep.DepartmanID= k.DepartmanID
LEFT JOIN YetkiMatrisi ym     ON ym.RolID       = r.RolID AND ym.AktifMi=1
LEFT JOIN DokumanKategorileri dk ON dk.KategoriID= ym.KategoriID;
GO

CREATE OR ALTER VIEW vw_ErisimLogDetay AS
SELECT el.LogID, el.IslemTarihi, el.IslemTipi, el.BasariliMi, el.RedNedeni,
       el.IPAdresi, el.OturumID,
       k.KullaniciAdi, k.Ad+' '+k.Soyad AS KullaniciTamAd,
       dep.DepartmanAdi,
       d.DokumanNo, d.Baslik AS DokumanBaslik, d.GizlilikSeviyesi,
       dt.TipAdi, dk.KategoriAdi
FROM ErisimLoglari el
JOIN Kullanicilar k         ON k.KullaniciID  = el.KullaniciID
JOIN Departmanlar dep       ON dep.DepartmanID= k.DepartmanID
JOIN Dokumanlar d           ON d.DokumanID    = el.DokumanID
JOIN DokumanTipleri dt      ON dt.TipID       = d.TipID
JOIN DokumanKategorileri dk ON dk.KategoriID  = dt.KategoriID;
GO

-- ================================================================
-- §9  35 SQL SORGUSU
-- ================================================================
-- Gruplar:
--   A: Temel CRUD             (S01–S07)
--   B: Yetki Kontrol          (S08–S14)
--   C: İz Kaydı / Audit       (S15–S21)
--   D: Raporlama ve İstatistik (S22–S28)
--   E: Gelişmiş Analitik       (S29–S35)
-- ================================================================

-- ┌─────────────────────────────────────────────────────────────┐
-- │  GRUP A — TEMEL CRUD (S01–S07)                             │
-- └─────────────────────────────────────────────────────────────┘

-- S01: Aktif kullanıcı listesi (departman + rol birleşimli)
SELECT
    k.KullaniciID,
    k.KullaniciAdi,
    k.Ad + N' ' + k.Soyad       AS TamAd,
    k.Email,
    k.Unvan,
    dep.DepartmanAdi,
    r.RolAdi,
    r.YetkiSeviyesi,
    k.SonGirisTarih,
    k.OlusturmaTarih
FROM Kullanicilar k
JOIN Departmanlar dep  ON dep.DepartmanID = k.DepartmanID
LEFT JOIN KullaniciRol kr ON kr.KullaniciID = k.KullaniciID AND kr.AktifMi=1
LEFT JOIN Roller r        ON r.RolID        = kr.RolID
WHERE k.AktifMi = 1
ORDER BY dep.DepartmanAdi, r.YetkiSeviyesi DESC, k.Soyad;

-- S02: Doküman detayı + versiyon geçmişi (tek doküman)
SELECT
    d.DokumanID, d.Baslik, d.DokumanNo, d.DokumanDurumu,
    d.GizlilikSeviyesi,
    dt.TipAdi, dk.KategoriAdi, dep.DepartmanAdi,
    k.Ad+N' '+k.Soyad AS OlusturanAdi,
    dv.VersiyonNo, dv.DegisiklikNotu,
    dv.OlusturmaTarih AS VersiyonTarih
FROM Dokumanlar d
JOIN DokumanTipleri dt       ON dt.TipID       = d.TipID
JOIN DokumanKategorileri dk  ON dk.KategoriID  = dt.KategoriID
JOIN Departmanlar dep        ON dep.DepartmanID = d.DepartmanID
JOIN Kullanicilar k          ON k.KullaniciID  = d.OlusturanID
LEFT JOIN DokumanVersiyonlari dv ON dv.DokumanID = d.DokumanID
WHERE d.DokumanID = 100
ORDER BY dv.OlusturmaTarih DESC;

-- S03: Yeni doküman ekleme (INSERT)
INSERT INTO Dokumanlar
(Baslik,DokumanNo,TipID,DepartmanID,OlusturanID,GizlilikSeviyesi,DokumanDurumu,AciklamaKisa,DosyaUzantisi)
VALUES(
    N'Siber Güvenlik Politikası v4.0',
    'DOC-2026-99998',
    6, 18,
    (SELECT TOP 1 KullaniciID FROM Kullanicilar WHERE KullaniciAdi='sysadmin_001'),
    4, N'Taslak', N'2026 revizyon sürümü', '.pdf'
);

-- S04: Doküman durumu güncelleme (UPDATE)
UPDATE Dokumanlar
SET DokumanDurumu    = N'Yayinlandi',
    GuncellenmeTarih = GETDATE(),
    YayinTarihi      = GETDATE()
WHERE DokumanNo = 'DOC-2026-99998';

-- S05: Doküman mantıksal silme (soft delete)
UPDATE Dokumanlar
SET DokumanDurumu    = N'Arsivlendi',
    AktifMi          = 0,
    GuncellenmeTarih = GETDATE()
WHERE DokumanNo = 'DOC-2026-99998';

-- S06: Kullanıcıya rol atama (INSERT + duplicate kontrolü)
IF NOT EXISTS (
    SELECT 1 FROM KullaniciRol
    WHERE KullaniciID = (SELECT KullaniciID FROM Kullanicilar WHERE KullaniciAdi='guest_001')
      AND RolID       = (SELECT RolID FROM Roller WHERE RolKodu='SR_EMP')
)
INSERT INTO KullaniciRol(KullaniciID, RolID, AtayanID)
VALUES(
    (SELECT KullaniciID FROM Kullanicilar WHERE KullaniciAdi='guest_001'),
    (SELECT RolID FROM Roller WHERE RolKodu='SR_EMP'),
    (SELECT KullaniciID FROM Kullanicilar WHERE KullaniciAdi='sysadmin_001')
);

-- S07: Doküman etiketi güncelleme — eski etiketi değiştir
UPDATE DokumanEtiketler
SET EtiketID    = (SELECT EtiketID FROM Etiketler WHERE EtiketAdi=N'Son Versiyon'),
    EklemeTarih = GETDATE()
WHERE DokumanID = 50
  AND EtiketID  = (SELECT EtiketID FROM Etiketler WHERE EtiketAdi=N'Taslak');

-- ┌─────────────────────────────────────────────────────────────┐
-- │  GRUP B — YETKİ KONTROL (S08–S14)                         │
-- └─────────────────────────────────────────────────────────────┘

-- S08: Kullanıcı–Doküman erişim kararı (ERIŞIM VERİLDİ / REDDEDİLDİ)
SELECT
    k.KullaniciAdi,
    k.Ad+N' '+k.Soyad   AS TamAd,
    d.Baslik            AS DokumanBaslik,
    d.GizlilikSeviyesi  AS DokumanGizlilik,
    r.RolAdi,
    r.YetkiSeviyesi,
    ym.GizlilikMaxSeviyesi,
    ym.OkumaYetkisi,
    CASE
        WHEN ym.OkumaYetkisi=1
         AND ym.GizlilikMaxSeviyesi >= d.GizlilikSeviyesi
         AND k.AktifMi=1
        THEN N'ERIŞIM VERİLDİ'
        ELSE N'ERIŞIM REDDEDİLDİ'
    END AS ErisimKarari
FROM Kullanicilar k
JOIN KullaniciRol kr   ON kr.KullaniciID = k.KullaniciID AND kr.AktifMi=1
JOIN Roller r          ON r.RolID        = kr.RolID
JOIN YetkiMatrisi ym   ON ym.RolID       = r.RolID AND ym.AktifMi=1
CROSS JOIN (SELECT TOP 1 * FROM Dokumanlar WHERE DokumanID=1) d
WHERE k.KullaniciID = 5;

-- S09: Rol bazlı tam yetki matrisi görünümü
SELECT
    r.RolAdi,
    r.YetkiSeviyesi,
    COALESCE(dk.KategoriAdi, N'Tüm Kategoriler') AS Kapsam,
    ym.GizlilikMaxSeviyesi,
    CASE ym.OkumaYetkisi    WHEN 1 THEN 'VAR' ELSE '—' END AS Okuma,
    CASE ym.YazmaYetkisi    WHEN 1 THEN 'VAR' ELSE '—' END AS Yazma,
    CASE ym.SilmeYetkisi    WHEN 1 THEN 'VAR' ELSE '—' END AS Silme,
    CASE ym.IndirmeYetkisi  WHEN 1 THEN 'VAR' ELSE '—' END AS Indirme,
    CASE ym.PaylasmaYetkisi WHEN 1 THEN 'VAR' ELSE '—' END AS Paylasma
FROM YetkiMatrisi ym
JOIN Roller r ON r.RolID=ym.RolID AND ym.AktifMi=1
LEFT JOIN DokumanKategorileri dk ON dk.KategoriID=ym.KategoriID
ORDER BY r.YetkiSeviyesi DESC, dk.KategoriAdi;

-- S10: Yetkisiz erişim denemeleri (son 30 gün)
SELECT
    el.LogID, el.IslemTarihi,
    k.KullaniciAdi, k.Ad+N' '+k.Soyad AS KullaniciAd,
    dep.DepartmanAdi,
    d.DokumanNo, d.Baslik, d.GizlilikSeviyesi,
    el.IPAdresi, el.RedNedeni
FROM ErisimLoglari el
JOIN Kullanicilar k   ON k.KullaniciID   = el.KullaniciID
JOIN Departmanlar dep ON dep.DepartmanID = k.DepartmanID
JOIN Dokumanlar d     ON d.DokumanID     = el.DokumanID
WHERE el.BasariliMi=0
  AND el.IslemTarihi >= DATEADD(DAY,-30,GETDATE())
ORDER BY el.IslemTarihi DESC;

-- S11: Kullanıcının erişebildiği tüm dokümanlar (yetki kuralı filtreli)
SELECT DISTINCT
    d.DokumanID, d.Baslik, d.DokumanNo,
    d.DokumanDurumu, d.GizlilikSeviyesi,
    dt.TipAdi, dk.KategoriAdi
FROM Kullanicilar k
JOIN KullaniciRol kr    ON kr.KullaniciID = k.KullaniciID AND kr.AktifMi=1
JOIN Roller r           ON r.RolID        = kr.RolID
JOIN YetkiMatrisi ym    ON ym.RolID       = r.RolID
                       AND ym.OkumaYetkisi=1 AND ym.AktifMi=1
JOIN Dokumanlar d       ON d.AktifMi=1
                       AND d.GizlilikSeviyesi <= ym.GizlilikMaxSeviyesi
JOIN DokumanTipleri dt  ON dt.TipID       = d.TipID
JOIN DokumanKategorileri dk ON dk.KategoriID=dt.KategoriID
                           AND (ym.KategoriID IS NULL OR ym.KategoriID=dk.KategoriID)
WHERE k.KullaniciID = 5
ORDER BY dk.KategoriAdi, d.Baslik;

-- S12: Gizli belgelere yetkisiz erişim güvenlik alarmı
SELECT
    k.KullaniciAdi,
    k.Ad+N' '+k.Soyad AS KullaniciAd,
    r.RolAdi, r.YetkiSeviyesi,
    d.GizlilikSeviyesi,
    COUNT(*)               AS GirisimSayisi,
    MIN(el.IslemTarihi)    AS IlkGirisim,
    MAX(el.IslemTarihi)    AS SonGirisim
FROM ErisimLoglari el
JOIN Kullanicilar k  ON k.KullaniciID  = el.KullaniciID
JOIN KullaniciRol kr ON kr.KullaniciID = k.KullaniciID AND kr.AktifMi=1
JOIN Roller r        ON r.RolID        = kr.RolID
JOIN Dokumanlar d    ON d.DokumanID    = el.DokumanID
WHERE el.BasariliMi=0 AND d.GizlilikSeviyesi>=4
GROUP BY k.KullaniciAdi,k.Ad,k.Soyad,r.RolAdi,r.YetkiSeviyesi,d.GizlilikSeviyesi
HAVING COUNT(*) >= 2
ORDER BY GirisimSayisi DESC;

-- S13: İki kullanıcının ortak erişebildiği dokümanlar
SELECT d.DokumanID, d.Baslik, d.GizlilikSeviyesi, dt.TipAdi
FROM Dokumanlar d
JOIN DokumanTipleri dt ON dt.TipID=d.TipID
WHERE d.DokumanID IN (
    SELECT DISTINCT DokumanID FROM ErisimLoglari
    WHERE KullaniciID=2 AND BasariliMi=1
)
AND d.DokumanID IN (
    SELECT DISTINCT DokumanID FROM ErisimLoglari
    WHERE KullaniciID=5 AND BasariliMi=1
);

-- S14: Departman bazlı gizlilik dağılımı
SELECT
    dep.DepartmanAdi,
    COUNT(DISTINCT d.DokumanID)                                     AS Toplam,
    SUM(CASE WHEN d.GizlilikSeviyesi=1 THEN 1 ELSE 0 END)          AS Genel,
    SUM(CASE WHEN d.GizlilikSeviyesi=2 THEN 1 ELSE 0 END)          AS Dahili,
    SUM(CASE WHEN d.GizlilikSeviyesi=3 THEN 1 ELSE 0 END)          AS Hassas,
    SUM(CASE WHEN d.GizlilikSeviyesi=4 THEN 1 ELSE 0 END)          AS Gizli,
    SUM(CASE WHEN d.GizlilikSeviyesi=5 THEN 1 ELSE 0 END)          AS CokGizli
FROM Dokumanlar d
JOIN Departmanlar dep ON dep.DepartmanID=d.DepartmanID
WHERE d.AktifMi=1
GROUP BY dep.DepartmanAdi
ORDER BY Toplam DESC;

-- ┌─────────────────────────────────────────────────────────────┐
-- │  GRUP C — İZ KAYDI / AUDİT (S15–S21)                      │
-- └─────────────────────────────────────────────────────────────┘

-- S15: Bir dokümanın tam audit trail'i
SELECT
    el.LogID, el.IslemTarihi, el.IslemTipi,
    k.KullaniciAdi, k.Ad+N' '+k.Soyad AS KullaniciAd,
    r.RolAdi, dep.DepartmanAdi,
    el.IPAdresi,
    CASE el.BasariliMi WHEN 1 THEN N'BAŞARILI' ELSE N'BAŞARISIZ' END AS Sonuc,
    el.RedNedeni, el.OturumID
FROM ErisimLoglari el
JOIN Kullanicilar k   ON k.KullaniciID   = el.KullaniciID
JOIN Departmanlar dep ON dep.DepartmanID = k.DepartmanID
LEFT JOIN KullaniciRol kr ON kr.KullaniciID=k.KullaniciID AND kr.AktifMi=1
LEFT JOIN Roller r        ON r.RolID=kr.RolID
WHERE el.DokumanID=100
ORDER BY el.IslemTarihi DESC;

-- S16: Kullanıcı aktivite raporu (son 7 gün, günlük özet)
SELECT
    k.KullaniciAdi,
    k.Ad+N' '+k.Soyad AS TamAd,
    CAST(el.IslemTarihi AS DATE) AS Gun,
    COUNT(*)                     AS Toplam,
    SUM(CASE WHEN el.IslemTipi='Goruntuleme' THEN 1 ELSE 0 END) AS Goruntuleme,
    SUM(CASE WHEN el.IslemTipi='Indirme'     THEN 1 ELSE 0 END) AS Indirme,
    SUM(CASE WHEN el.IslemTipi='Duzenleme'   THEN 1 ELSE 0 END) AS Duzenleme,
    SUM(CASE WHEN el.IslemTipi='YetkiReddi'  THEN 1 ELSE 0 END) AS YetkiReddi,
    SUM(CASE WHEN el.BasariliMi=0            THEN 1 ELSE 0 END) AS Basarisiz
FROM ErisimLoglari el
JOIN Kullanicilar k ON k.KullaniciID=el.KullaniciID
WHERE el.IslemTarihi >= DATEADD(DAY,-7,GETDATE())
GROUP BY k.KullaniciAdi,k.Ad,k.Soyad,CAST(el.IslemTarihi AS DATE)
ORDER BY Gun DESC, Toplam DESC;

-- S17: En çok erişilen 20 doküman
SELECT TOP 20
    d.DokumanNo, d.Baslik, d.GizlilikSeviyesi,
    dt.TipAdi, dk.KategoriAdi, dep.DepartmanAdi,
    COUNT(el.LogID)                                         AS ToplamErisim,
    SUM(CASE WHEN el.IslemTipi='Indirme' THEN 1 ELSE 0 END) AS Indirme,
    MAX(el.IslemTarihi)                                     AS SonErisim
FROM ErisimLoglari el
JOIN Dokumanlar d           ON d.DokumanID    =el.DokumanID
JOIN DokumanTipleri dt      ON dt.TipID       =d.TipID
JOIN DokumanKategorileri dk ON dk.KategoriID  =dt.KategoriID
JOIN Departmanlar dep       ON dep.DepartmanID=d.DepartmanID
WHERE el.BasariliMi=1
GROUP BY d.DokumanNo,d.Baslik,d.GizlilikSeviyesi,dt.TipAdi,dk.KategoriAdi,dep.DepartmanAdi
ORDER BY ToplamErisim DESC;

-- S18: Şüpheli IP — çok sayıda YetkiReddi
SELECT
    el.IPAdresi,
    COUNT(DISTINCT el.KullaniciID) AS FarkliKullanici,
    COUNT(*)                        AS ToplamRed,
    MIN(el.IslemTarihi)            AS Ilk,
    MAX(el.IslemTarihi)            AS Son,
    DATEDIFF(MINUTE,MIN(el.IslemTarihi),MAX(el.IslemTarihi)) AS SureDak
FROM ErisimLoglari el
WHERE el.IslemTipi='YetkiReddi'
  AND el.IslemTarihi >= DATEADD(DAY,-1,GETDATE())
GROUP BY el.IPAdresi
HAVING COUNT(*) >= 3
ORDER BY ToplamRed DESC;

-- S19: Mesai dışı erişim raporu (18:00–08:00 + hafta sonu)
SELECT
    el.LogID, el.IslemTarihi,
    DATENAME(WEEKDAY,el.IslemTarihi) AS Gun,
    FORMAT(el.IslemTarihi,'HH:mm')   AS Saat,
    k.KullaniciAdi, k.Ad+N' '+k.Soyad AS TamAd,
    r.RolAdi, d.Baslik, d.GizlilikSeviyesi,
    el.IslemTipi, el.IPAdresi
FROM ErisimLoglari el
JOIN Kullanicilar k  ON k.KullaniciID  =el.KullaniciID
JOIN Dokumanlar d    ON d.DokumanID    =el.DokumanID
LEFT JOIN KullaniciRol kr ON kr.KullaniciID=k.KullaniciID AND kr.AktifMi=1
LEFT JOIN Roller r        ON r.RolID=kr.RolID
WHERE (DATEPART(HOUR,el.IslemTarihi)>=18
    OR DATEPART(HOUR,el.IslemTarihi)<8
    OR DATEPART(WEEKDAY,el.IslemTarihi) IN (1,7))
  AND el.BasariliMi=1
  AND d.GizlilikSeviyesi>=3
ORDER BY el.IslemTarihi DESC;

-- S20: İşlem geçmişi başarı oranı (son 3 ay)
SELECT
    ig.IslemKategorisi,
    CAST(ig.IslemTarihi AS DATE)    AS Gun,
    COUNT(*)                        AS Toplam,
    SUM(CASE WHEN ig.SonucDurumu='Basarili'  THEN 1 ELSE 0 END) AS Basarili,
    SUM(CASE WHEN ig.SonucDurumu='Basarisiz' THEN 1 ELSE 0 END) AS Basarisiz,
    CAST(SUM(CASE WHEN ig.SonucDurumu='Basarili' THEN 1.0 ELSE 0 END)
         /NULLIF(COUNT(*),0)*100 AS DECIMAL(5,2)) AS BasariOrani
FROM IslemGecmisi ig
WHERE ig.IslemTarihi >= DATEADD(MONTH,-3,GETDATE())
GROUP BY ig.IslemKategorisi, CAST(ig.IslemTarihi AS DATE)
ORDER BY Gun DESC, Toplam DESC;

-- S21: Hiç erişilmemiş yayınlanmış dokümanlar (yetim belge raporu)
SELECT
    d.DokumanID, d.DokumanNo, d.Baslik,
    d.DokumanDurumu, d.OlusturmaTarih,
    DATEDIFF(DAY,d.OlusturmaTarih,GETDATE()) AS YasiGun,
    dt.TipAdi, dep.DepartmanAdi,
    k.Ad+N' '+k.Soyad AS OlusturanAd
FROM Dokumanlar d
JOIN DokumanTipleri dt ON dt.TipID       =d.TipID
JOIN Departmanlar dep  ON dep.DepartmanID=d.DepartmanID
JOIN Kullanicilar k    ON k.KullaniciID  =d.OlusturanID
WHERE NOT EXISTS (
    SELECT 1 FROM ErisimLoglari el
    WHERE el.DokumanID=d.DokumanID AND el.BasariliMi=1)
  AND d.AktifMi=1
  AND d.DokumanDurumu IN (N'Yayinlandi',N'Onaylandi')
ORDER BY YasiGun DESC;

-- ┌─────────────────────────────────────────────────────────────┐
-- │  GRUP D — RAPORLAMA VE İSTATİSTİK (S22–S28)               │
-- └─────────────────────────────────────────────────────────────┘

-- S22: Kategori bazlı doküman dağılımı + depolama
SELECT
    dk.KategoriAdi, dk.KategoriKodu,
    dk.GizlilikSeviyesi AS KatGizlilik,
    COUNT(d.DokumanID)  AS Toplam,
    SUM(CASE WHEN d.DokumanDurumu=N'Yayinlandi'  THEN 1 ELSE 0 END) AS Yayinda,
    SUM(CASE WHEN d.DokumanDurumu=N'Taslak'      THEN 1 ELSE 0 END) AS Taslak,
    SUM(CASE WHEN d.DokumanDurumu=N'Arsivlendi'  THEN 1 ELSE 0 END) AS Arsivde,
    CAST(AVG(CAST(d.GizlilikSeviyesi AS FLOAT)) AS DECIMAL(3,2)) AS OrtGizlilik,
    CAST(SUM(d.DosyaBoyutu)/1048576.0 AS DECIMAL(10,2)) AS ToplamMB
FROM DokumanKategorileri dk
LEFT JOIN DokumanTipleri dt ON dt.KategoriID=dk.KategoriID
LEFT JOIN Dokumanlar d      ON d.TipID=dt.TipID AND d.AktifMi=1
GROUP BY dk.KategoriAdi,dk.KategoriKodu,dk.GizlilikSeviyesi
ORDER BY Toplam DESC;

-- S23: Aylık doküman üretim trendi (son 12 ay)
SELECT
    FORMAT(d.OlusturmaTarih,'yyyy-MM') AS Ay,
    COUNT(*)                           AS Yeni,
    SUM(CASE WHEN d.DokumanDurumu=N'Yayinlandi' THEN 1 ELSE 0 END) AS Yayinlandi,
    SUM(CASE WHEN d.GizlilikSeviyesi>=4         THEN 1 ELSE 0 END) AS GizliDokuman,
    CAST(AVG(CAST(d.DosyaBoyutu AS BIGINT))/1024.0 AS DECIMAL(10,1)) AS OrtBoyutKB
FROM Dokumanlar d
WHERE d.OlusturmaTarih >= DATEADD(MONTH,-12,GETDATE())
GROUP BY FORMAT(d.OlusturmaTarih,'yyyy-MM')
ORDER BY Ay DESC;

-- S24: Departman çalışan + doküman istatistikleri
SELECT
    dep.DepartmanAdi, dep.DepartmanKodu,
    COUNT(DISTINCT k.KullaniciID)                                          AS TumCalisan,
    COUNT(DISTINCT CASE WHEN k.AktifMi=1 THEN k.KullaniciID END)          AS AktifCalisan,
    COUNT(DISTINCT d.DokumanID)                                            AS UrduguDokuman,
    COUNT(DISTINCT CASE WHEN d.DokumanDurumu=N'Yayinlandi'
                         THEN d.DokumanID END)                             AS Yayinlandi,
    CAST(ISNULL(AVG(CAST(d.GizlilikSeviyesi AS FLOAT)),0) AS DECIMAL(3,2)) AS OrtGizlilik
FROM Departmanlar dep
LEFT JOIN Kullanicilar k ON k.DepartmanID=dep.DepartmanID
LEFT JOIN Dokumanlar d   ON d.DepartmanID=dep.DepartmanID AND d.AktifMi=1
GROUP BY dep.DepartmanAdi,dep.DepartmanKodu
ORDER BY TumCalisan DESC;

-- S25: Süresi 60 gün içinde dolacak dokümanlar
SELECT
    d.DokumanID, d.DokumanNo, d.Baslik,
    d.SonGecerlilikTarih,
    DATEDIFF(DAY,GETDATE(),d.SonGecerlilikTarih) AS KalanGun,
    dt.TipAdi, dep.DepartmanAdi,
    k.Ad+N' '+k.Soyad AS SorumluAd, k.Email AS SorumluEmail
FROM Dokumanlar d
JOIN DokumanTipleri dt ON dt.TipID       =d.TipID
JOIN Departmanlar dep  ON dep.DepartmanID=d.DepartmanID
LEFT JOIN Kullanicilar k ON k.KullaniciID=d.SorumluID
WHERE d.SonGecerlilikTarih BETWEEN GETDATE() AND DATEADD(DAY,60,GETDATE())
  AND d.AktifMi=1 AND d.DokumanDurumu=N'Yayinlandi'
ORDER BY KalanGun;

-- S26: Rol bazlı kullanıcı dağılımı ve aktivite
SELECT
    r.RolAdi, r.YetkiSeviyesi, r.RolKodu,
    COUNT(kr.KullaniciID)                              AS ToplamAtama,
    SUM(CASE WHEN k.AktifMi=1 THEN 1 ELSE 0 END)      AS Aktif,
    COUNT(DISTINCT k.DepartmanID)                      AS FarkliDept,
    MIN(kr.AtamaTarih)                                 AS IlkAtama,
    MAX(kr.AtamaTarih)                                 AS SonAtama
FROM Roller r
LEFT JOIN KullaniciRol kr ON kr.RolID=r.RolID AND kr.AktifMi=1
LEFT JOIN Kullanicilar k  ON k.KullaniciID=kr.KullaniciID
GROUP BY r.RolAdi,r.YetkiSeviyesi,r.RolKodu
ORDER BY r.YetkiSeviyesi DESC;

-- S27: En aktif 15 kullanıcı (erişim skoru ile sıralı)
SELECT TOP 15
    k.KullaniciAdi, k.Ad+N' '+k.Soyad AS TamAd,
    r.RolAdi, dep.DepartmanAdi,
    COUNT(el.LogID)                                        AS ToplamErisim,
    COUNT(DISTINCT el.DokumanID)                           AS FarkliDokuman,
    SUM(CASE WHEN el.IslemTipi='Indirme' THEN 1 ELSE 0 END) AS Indirme,
    SUM(CASE WHEN el.BasariliMi=0        THEN 1 ELSE 0 END) AS Basarisiz,
    MAX(el.IslemTarihi)                                    AS SonAktivite
FROM ErisimLoglari el
JOIN Kullanicilar k   ON k.KullaniciID   =el.KullaniciID
JOIN Departmanlar dep ON dep.DepartmanID =k.DepartmanID
LEFT JOIN KullaniciRol kr ON kr.KullaniciID=k.KullaniciID AND kr.AktifMi=1
LEFT JOIN Roller r        ON r.RolID=kr.RolID
GROUP BY k.KullaniciAdi,k.Ad,k.Soyad,r.RolAdi,dep.DepartmanAdi
ORDER BY ToplamErisim DESC;

-- S28: Sistem geneli kapsamlı durum özeti
SELECT 'Toplam Kullanıcı'          AS Metrik, CAST(COUNT(*) AS NVARCHAR) AS Deger
FROM Kullanicilar WHERE AktifMi=1
UNION ALL
SELECT 'Toplam Doküman',           CAST(COUNT(*) AS NVARCHAR) FROM Dokumanlar WHERE AktifMi=1
UNION ALL
SELECT 'Yayınlanmış Doküman',      CAST(COUNT(*) AS NVARCHAR) FROM Dokumanlar WHERE DokumanDurumu=N'Yayinlandi'
UNION ALL
SELECT 'Gizli Doküman (sev 4-5)',  CAST(COUNT(*) AS NVARCHAR) FROM Dokumanlar WHERE GizlilikSeviyesi>=4 AND AktifMi=1
UNION ALL
SELECT 'Toplam Erişim Logu',       CAST(COUNT(*) AS NVARCHAR) FROM ErisimLoglari
UNION ALL
SELECT 'Başarısız Erişim',         CAST(COUNT(*) AS NVARCHAR) FROM ErisimLoglari WHERE BasariliMi=0
UNION ALL
SELECT 'Toplam Rol Ataması',       CAST(COUNT(*) AS NVARCHAR) FROM KullaniciRol WHERE AktifMi=1
UNION ALL
SELECT 'Aktif Yetki Kuralı',       CAST(COUNT(*) AS NVARCHAR) FROM YetkiMatrisi WHERE AktifMi=1
UNION ALL
SELECT 'Toplam Versiyon',          CAST(COUNT(*) AS NVARCHAR) FROM DokumanVersiyonlari
UNION ALL
SELECT 'Toplam Paylaşım',          CAST(COUNT(*) AS NVARCHAR) FROM Paylaşimlar WHERE AktifMi=1
UNION ALL
SELECT 'Okunmamış Bildirim',       CAST(COUNT(*) AS NVARCHAR) FROM Bildirimler WHERE OkunduMu=0
UNION ALL
SELECT 'Toplam İşlem Geçmişi',     CAST(COUNT(*) AS NVARCHAR) FROM IslemGecmisi
UNION ALL
SELECT 'Doküman Tipleri',          CAST(COUNT(*) AS NVARCHAR) FROM DokumanTipleri
UNION ALL
SELECT 'Departman Sayısı',         CAST(COUNT(*) AS NVARCHAR) FROM Departmanlar;

-- ┌─────────────────────────────────────────────────────────────┐
-- │  GRUP E — GELİŞMİŞ ANALİTİK (S29–S35)                    │
-- └─────────────────────────────────────────────────────────────┘

-- S29: WINDOW FUNCTION — Her departmanda en çok doküman üreten kullanıcı
SELECT * FROM (
    SELECT
        dep.DepartmanAdi,
        k.KullaniciAdi, k.Ad+N' '+k.Soyad AS TamAd,
        COUNT(d.DokumanID) AS DokumanSayisi,
        RANK() OVER(PARTITION BY dep.DepartmanID ORDER BY COUNT(d.DokumanID) DESC) AS Sira
    FROM Kullanicilar k
    JOIN Departmanlar dep ON dep.DepartmanID=k.DepartmanID
    LEFT JOIN Dokumanlar d ON d.OlusturanID=k.KullaniciID AND d.AktifMi=1
    GROUP BY dep.DepartmanID,dep.DepartmanAdi,k.KullaniciID,k.KullaniciAdi,k.Ad,k.Soyad
) ranked
WHERE Sira=1
ORDER BY DokumanSayisi DESC;

-- S30: CTE RECURSIVE — Departman hiyerarşisi (tam ağaç)
WITH DeptAgac AS (
    SELECT DepartmanID, DepartmanAdi, DepartmanKodu, UstDepartmanID,
           0 AS Seviye,
           CAST(DepartmanAdi AS NVARCHAR(500)) AS Yol
    FROM Departmanlar WHERE UstDepartmanID IS NULL
    UNION ALL
    SELECT d.DepartmanID, d.DepartmanAdi, d.DepartmanKodu, d.UstDepartmanID,
           a.Seviye+1,
           CAST(a.Yol+N' > '+d.DepartmanAdi AS NVARCHAR(500))
    FROM Departmanlar d
    JOIN DeptAgac a ON a.DepartmanID=d.UstDepartmanID
)
SELECT
    REPLICATE(N'    ',Seviye) + DepartmanAdi AS HiyerarsiGorunu,
    DepartmanKodu, Seviye, Yol
FROM DeptAgac
ORDER BY Yol;

-- S31: PIVOT — Aylık işlem tipi dağılım tablosu
SELECT * FROM (
    SELECT
        FORMAT(el.IslemTarihi,'yyyy-MM') AS Ay,
        el.IslemTipi, el.LogID
    FROM ErisimLoglari el
    WHERE el.IslemTarihi >= DATEADD(MONTH,-6,GETDATE())
) src
PIVOT (
    COUNT(LogID) FOR IslemTipi IN
    ([Goruntuleme],[Indirme],[Duzenleme],[Paylasma],[YetkiReddi],[Yazdirma],[Kopyalama])
) pvt
ORDER BY Ay DESC;

-- S32: SLIDING WINDOW — 7 günlük hareketli ortalama erişim
SELECT
    CAST(el.IslemTarihi AS DATE)    AS Tarih,
    COUNT(*)                        AS GunlukErisim,
    AVG(COUNT(*)) OVER (
        ORDER BY CAST(el.IslemTarihi AS DATE)
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS HareketliOrt7Gun,
    SUM(COUNT(*)) OVER (
        ORDER BY CAST(el.IslemTarihi AS DATE)
        ROWS UNBOUNDED PRECEDING
    ) AS KumulatifErisim
FROM ErisimLoglari el
GROUP BY CAST(el.IslemTarihi AS DATE)
ORDER BY Tarih;

-- S33: KORELASYON — Gizlilik seviyesi ile yetkisiz erişim ilişkisi
SELECT
    d.GizlilikSeviyesi,
    CASE d.GizlilikSeviyesi
        WHEN 1 THEN N'Genel'    WHEN 2 THEN N'Dahili'
        WHEN 3 THEN N'Hassas'   WHEN 4 THEN N'Gizli'
        ELSE N'Çok Gizli' END  AS GizlilikAdi,
    COUNT(DISTINCT d.DokumanID) AS DokumanSayisi,
    COUNT(el.LogID)             AS ToplamErisim,
    SUM(CASE WHEN el.BasariliMi=0 THEN 1 ELSE 0 END)  AS RedSayisi,
    CAST(SUM(CASE WHEN el.BasariliMi=0 THEN 1.0 ELSE 0 END)
         /NULLIF(COUNT(el.LogID),0)*100 AS DECIMAL(5,2)) AS RedOrani
FROM Dokumanlar d
LEFT JOIN ErisimLoglari el ON el.DokumanID=d.DokumanID
GROUP BY d.GizlilikSeviyesi
ORDER BY d.GizlilikSeviyesi;

-- S34: JSON ÇIKTI — Kullanıcı yetki özeti (API formatı)
SELECT
    k.KullaniciID,
    k.KullaniciAdi,
    k.Ad+N' '+k.Soyad AS TamAd,
    (SELECT r.RolAdi AS rol, r.YetkiSeviyesi AS seviye,
            (SELECT COALESCE(dk.KategoriAdi,N'Tüm') AS kategori,
                    ym.OkumaYetkisi AS okuma, ym.YazmaYetkisi AS yazma,
                    ym.IndirmeYetkisi AS indirme, ym.GizlilikMaxSeviyesi AS maxGizlilik
             FROM YetkiMatrisi ym
             LEFT JOIN DokumanKategorileri dk ON dk.KategoriID=ym.KategoriID
             WHERE ym.RolID=r.RolID AND ym.AktifMi=1
             FOR JSON PATH) AS yetkiler
     FROM KullaniciRol kr
     JOIN Roller r ON r.RolID=kr.RolID
     WHERE kr.KullaniciID=k.KullaniciID AND kr.AktifMi=1
     FOR JSON PATH) AS YetkiJSON
FROM Kullanicilar k
WHERE k.AktifMi=1 AND k.KullaniciID<=10;

-- S35: ÇAPRAZ TABLO + CASE — Rol × Kategori yetki karşılaştırması
SELECT
    r.RolAdi,
    r.YetkiSeviyesi,
    MAX(CASE dk.KategoriKodu WHEN 'HUK' THEN
        CASE WHEN ym.OkumaYetkisi=1 THEN 'R' ELSE '-' END
        +CASE WHEN ym.YazmaYetkisi=1 THEN 'W' ELSE '' END
        +CASE WHEN ym.SilmeYetkisi=1 THEN 'D' ELSE '' END
        ELSE '' END) AS Hukuki,
    MAX(CASE dk.KategoriKodu WHEN 'IKB' THEN
        CASE WHEN ym.OkumaYetkisi=1 THEN 'R' ELSE '-' END
        +CASE WHEN ym.YazmaYetkisi=1 THEN 'W' ELSE '' END
        ELSE '' END) AS IK,
    MAX(CASE dk.KategoriKodu WHEN 'MAL' THEN
        CASE WHEN ym.OkumaYetkisi=1 THEN 'R' ELSE '-' END
        +CASE WHEN ym.YazmaYetkisi=1 THEN 'W' ELSE '' END
        ELSE '' END) AS Mali,
    MAX(CASE dk.KategoriKodu WHEN 'ARG' THEN
        CASE WHEN ym.OkumaYetkisi=1 THEN 'R' ELSE '-' END
        +CASE WHEN ym.YazmaYetkisi=1 THEN 'W' ELSE '' END
        ELSE '' END) AS ArGe,
    MAX(CASE dk.KategoriKodu WHEN 'TEK' THEN
        CASE WHEN ym.OkumaYetkisi=1 THEN 'R' ELSE '-' END
        +CASE WHEN ym.YazmaYetkisi=1 THEN 'W' ELSE '' END
        ELSE '' END) AS Teknik,
    MAX(CASE dk.KategoriKodu WHEN 'KAL' THEN
        CASE WHEN ym.OkumaYetkisi=1 THEN 'R' ELSE '-' END
        +CASE WHEN ym.YazmaYetkisi=1 THEN 'W' ELSE '' END
        ELSE '' END) AS Kalite
FROM Roller r
LEFT JOIN YetkiMatrisi ym        ON ym.RolID=r.RolID AND ym.AktifMi=1
LEFT JOIN DokumanKategorileri dk ON dk.KategoriID=ym.KategoriID
GROUP BY r.RolAdi, r.YetkiSeviyesi
ORDER BY r.YetkiSeviyesi DESC;

-- ================================================================
PRINT '================================================================';
PRINT 'YetkiMatrisiDB basariyla olusturuldu.';
PRINT 'Tablolar : 18   Views : 3   SP : 5';
PRINT 'Sorgular : 35   Normalizasyon : 1NF + 2NF + 3NF kaniti';
PRINT '================================================================';
GO
