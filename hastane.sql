DROP SCHEMA IF EXISTS "iller" CASCADE;
DROP SCHEMA IF EXISTS "vatandas" CASCADE;
DROP SCHEMA IF EXISTS "randevular" CASCADE;

CREATE SCHEMA "iller";
CREATE SCHEMA "vatandas";
CREATE SCHEMA "randevular";

CREATE TABLE "vatandas"."Vatandas" (
    "vatandasId" SERIAL NOT NULL,
	"tcKimlikNo" BIGINT NOT NULL,
	"ad" VARCHAR(50) NOT NULL,
    "soyad" VARCHAR(50) NOT NULL,
	"adres" TEXT NOT NULL,  -- text sınırsızdır
	
	CONSTRAINT "vatandasPK" PRIMARY KEY ("vatandasId"),
    CONSTRAINT "vatandasUnique" UNIQUE ("tcKimlikNo"),
    CONSTRAINT "tcHaneKontrol" CHECK ("tcKimlikNo" BETWEEN 10000000000 AND 99999999999)
);

CREATE TABLE "vatandas"."Personel" (
    "personelId" INT NOT NULL, -- hem pk hem de fk olur, vatandasIdden alır
    "gorevTuru" VARCHAR(50) NOT NULL, 
    "unvan" VARCHAR(50),
    "sicilNo" VARCHAR(20) NOT NULL,
    "sifre" VARCHAR(20) DEFAULT '1234',

    CONSTRAINT "personelPK" PRIMARY KEY ("personelId"),
    CONSTRAINT "personelSicilUnique" UNIQUE ("sicilNo"),

    CONSTRAINT "personelFK" FOREIGN KEY ("personelId") 
        REFERENCES "vatandas"."Vatandas" ("vatandasId") 
        ON DELETE CASCADE
);

CREATE TABLE "vatandas"."Doktor" (
    "doktorId" INT NOT NULL,
    "uzmanlikAlani" VARCHAR(100) NOT NULL,

    CONSTRAINT "doktorPK" PRIMARY KEY ("doktorId"),

    CONSTRAINT "doktorFK" FOREIGN KEY ("doktorId") 
        REFERENCES "vatandas"."Personel" ("personelId") 
        ON DELETE CASCADE
);

CREATE TABLE "iller"."Iller" (
    "ilPlaka" INT NOT NULL,
    "ilAdi" VARCHAR(50) NOT NULL,

    CONSTRAINT "illerPK" PRIMARY KEY ("ilPlaka"),
    CONSTRAINT "ilAdiUnique" UNIQUE ("ilAdi")
);

CREATE TABLE "iller"."PoliklinikTuru" (
    "turId" SERIAL NOT NULL,
    "turAdi" VARCHAR(50) NOT NULL,

    CONSTRAINT "turPK" PRIMARY KEY ("turId"),
    CONSTRAINT "turAdiUnique" UNIQUE ("turAdi")
);

CREATE TABLE "iller"."Hastane" (
    "hastaneId" SERIAL NOT NULL,
    "hastaneAdi" VARCHAR(100) NOT NULL,
    "ilPlaka" INT NOT NULL,
    "bashekimId" INT, 
    "toplamCiro" DECIMAL(15, 2) DEFAULT 0,

    CONSTRAINT "hastanePK" PRIMARY KEY ("hastaneId"),
    CONSTRAINT "bashekimUnique" UNIQUE ("bashekimId"),

    CONSTRAINT "hastaneIlFK" FOREIGN KEY ("ilPlaka") 
        REFERENCES "iller"."Iller" ("ilPlaka") 
        ON DELETE CASCADE,

    CONSTRAINT "hastaneBashekimFK" FOREIGN KEY ("bashekimId") 
        REFERENCES "vatandas"."Doktor" ("doktorId") 
        ON DELETE SET NULL -- başhekim silinirse hastane silinmesin sadece yöneticisi düşsün
);

CREATE TABLE "iller"."Poliklinik" (
    "poliklinikId" SERIAL NOT NULL,
    "hastaneId" INT NOT NULL,
    "turId" INT NOT NULL,

    CONSTRAINT "poliklinikPK" PRIMARY KEY ("poliklinikId"),
    CONSTRAINT "hastaneTurUnique" UNIQUE ("hastaneId", "turId"),-- bir hastanede aynı türden sadece 1 poliklinik olmalı

    CONSTRAINT "poliklinikHastaneFK" FOREIGN KEY ("hastaneId") 
        REFERENCES "iller"."Hastane" ("hastaneId") 
        ON DELETE CASCADE,

    CONSTRAINT "poliklinikTurFK" FOREIGN KEY ("turId") 
        REFERENCES "iller"."PoliklinikTuru" ("turId") 
        ON DELETE CASCADE
);

CREATE TABLE "iller"."Oda" (
    "hastaneId" INT NOT NULL,
    "odaNo" VARCHAR(10) NOT NULL,
    "kapasite" INT DEFAULT 1,

    CONSTRAINT "odaPK" PRIMARY KEY ("hastaneId", "odaNo"), -- bir hastanede oda numarası tekrar edemez
    
    CONSTRAINT "kapasiteKontrol" CHECK ("kapasite" >= 1), -- kapasite en az 1 olmalı

    CONSTRAINT "odaHastaneFK" FOREIGN KEY ("hastaneId") 
        REFERENCES "iller"."Hastane" ("hastaneId") 
        ON DELETE CASCADE
);

CREATE TABLE "vatandas"."Hasta" (
    "hastaId" INT NOT NULL,
    "sigortaTuru" VARCHAR(20) NOT NULL,
    
    CONSTRAINT "hastaPK" PRIMARY KEY ("hastaId"),
    
    CONSTRAINT "sigortaTurCheck" CHECK ("sigortaTuru" IN ('SGK', 'Özel', 'Yok')),
    
    CONSTRAINT "hastaFK" FOREIGN KEY ("hastaId")
        REFERENCES "vatandas"."Vatandas" ("vatandasId")
        ON DELETE CASCADE
);

CREATE TABLE "vatandas"."HastaYakini" (
    "yakinId" INT NOT NULL,
    "hastaId" INT NOT NULL,
    "yakinlikDerecesi" VARCHAR(50) NOT NULL, 
    
    CONSTRAINT "hastaYakiniPK" PRIMARY KEY ("yakinId", "hastaId"),
    
    CONSTRAINT "yakinVatandasFK" FOREIGN KEY ("yakinId")
        REFERENCES "vatandas"."Vatandas" ("vatandasId")
        ON DELETE CASCADE,
        
    CONSTRAINT "yakinHastaFK" FOREIGN KEY ("hastaId")
        REFERENCES "vatandas"."Hasta" ("hastaId")
        ON DELETE CASCADE
);

CREATE TABLE "vatandas"."HastanePersonel" (
    "hastanePersonelId" INT NOT NULL,
    "personelId" INT NOT NULL,
    "hastaneId" INT NOT NULL,
    
    CONSTRAINT "hastanePersonelPK" PRIMARY KEY ("hastanePersonelId"),
    
    CONSTRAINT "hpPersonelFK" FOREIGN KEY ("personelId") 
        REFERENCES "vatandas"."Personel" ("personelId") 
        ON DELETE CASCADE,
        
    CONSTRAINT "hpHastaneFK" FOREIGN KEY ("hastaneId")
        REFERENCES "iller"."Hastane" ("hastaneId")
        ON DELETE CASCADE,
        
    CONSTRAINT "ayniKayitEngelleme" UNIQUE ("personelId", "hastaneId")  --aynı hastanede aynı id'ye sahip 2 personel bulunmasını engeller
);

CREATE TABLE "randevular"."Randevu" (
    "randevuId" SERIAL NOT NULL,
    "hastaId" INT NOT NULL,
    "doktorId" INT NOT NULL,
    "poliklinikId" INT NOT NULL,
    "randevuTarihi" TIMESTAMP NOT NULL,
    
    CONSTRAINT "randevuPK" PRIMARY KEY ("randevuId"),
    
    CONSTRAINT "hastaRandevuFK" FOREIGN KEY ("hastaId") 
        REFERENCES "vatandas"."Hasta" ("hastaId") 
        ON DELETE CASCADE,
        
    CONSTRAINT "doktorRandevuFK" FOREIGN KEY ("doktorId") 
        REFERENCES "vatandas"."Doktor" ("doktorId") 
        ON DELETE CASCADE,
        
    CONSTRAINT "poliklinikRandevuFK" FOREIGN KEY ("poliklinikId") 
        REFERENCES "iller"."Poliklinik" ("poliklinikId") 
        ON DELETE CASCADE,
        
    CONSTRAINT "doktorZamanUnique" UNIQUE ("doktorId", "randevuTarihi")
);

CREATE TABLE "randevular"."RandevuIptalLog" (
    "logId" SERIAL PRIMARY KEY,
    "randevuId" INT,
    "hastaId" INT,
    "doktorId" INT,
    "iptalTarihi" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "iptalNedeni" VARCHAR(255) DEFAULT 'Kullanıcı tarafından silindi'
);

CREATE TABLE "randevular"."Yatis" (
    "yatisId" SERIAL NOT NULL,
    "hastaId" INT NOT NULL,
    "hastaneId" INT NOT NULL,
    "odaNo" VARCHAR(10) NOT NULL,
    "yatisTarihi" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "taburcuTarihi" TIMESTAMP, -- boş ise hasta hala yatıyor demektir

    CONSTRAINT "yatisPK" PRIMARY KEY ("yatisId"),

    -- Bir hasta aynı anda sadece bir yerde yatıyor olabilir

    CONSTRAINT "yatisHastaFK" FOREIGN KEY ("hastaId") 
        REFERENCES "vatandas"."Hasta" ("hastaId") 
        ON DELETE CASCADE,

    CONSTRAINT "yatisOdaFK" FOREIGN KEY ("hastaneId", "odaNo") 
        REFERENCES "iller"."Oda" ("hastaneId", "odaNo") 
        ON DELETE CASCADE
);

CREATE TABLE "randevular"."Muayene" (
    "muayeneId" SERIAL NOT NULL,
    "randevuId" INT NOT NULL,
    "tani" TEXT NOT NULL,
    "muayeneSonuc" TEXT NOT NULL,
    "islemTarihi" TIMESTAMP DEFAULT CURRENT_TIMESTAMP, --işlem tarihini otomatik işlemin yapıldığı tarih yapar
    
    CONSTRAINT "muayenePK" PRIMARY KEY ("muayeneId"),
    
    CONSTRAINT "muayeneFK" FOREIGN KEY ("randevuId") 
        REFERENCES "randevular"."Randevu" ("randevuId") 
        ON DELETE CASCADE,
        
    CONSTRAINT "muayeneUnique" UNIQUE ("randevuId")
);

CREATE TABLE "randevular"."Tahlil" (
    "tahlilId" SERIAL NOT NULL,
    "muayeneId" INT NOT NULL,
    "tahlilTuru" VARCHAR(50) NOT NULL,
    "tahlilSonuc" TEXT NOT NULL,
    
    CONSTRAINT "tahlilPK" PRIMARY KEY ("tahlilId"),
    
    CONSTRAINT "tahlilFK" FOREIGN KEY ("muayeneId") 
        REFERENCES "randevular"."Muayene" ("muayeneId") 
        ON DELETE CASCADE
);

CREATE TABLE "randevular"."Recete" (
    "receteId" SERIAL NOT NULL,
    "muayeneId" INT NOT NULL,
    "doktorId" INT NOT NULL,
    "hastaId" INT NOT NULL,
    "receteTarihi" TIMESTAMP NOT NULL,
    
    CONSTRAINT "recetePK" PRIMARY KEY ("receteId"),
    
    CONSTRAINT "rMuayeneFK" FOREIGN KEY ("muayeneId") 
        REFERENCES "randevular"."Muayene" ("muayeneId") 
        ON DELETE CASCADE,
        
    CONSTRAINT "rDoktorFK" FOREIGN KEY ("doktorId") 
        REFERENCES "vatandas"."Doktor" ("doktorId") 
        ON DELETE CASCADE,
        
    CONSTRAINT "rHastaFK" FOREIGN KEY ("hastaId") 
        REFERENCES "vatandas"."Hasta" ("hastaId") 
        ON DELETE CASCADE
);

CREATE TABLE "randevular"."Ilaclar" (
    "barkod" BIGINT NOT NULL,
    "ilacAdi" VARCHAR(50) NOT NULL,
    
    CONSTRAINT "ilaclarPK" PRIMARY KEY ("barkod")
);

CREATE TABLE "randevular"."ReceteDetay" (
    "receteId" INT NOT NULL,
    "ilacId" BIGINT NOT NULL,
    "kullanimDozu" VARCHAR(100) NOT NULL,
    "adet" INT NOT NULL,  --bunun 0'dan büyük olup olmadığı kontrol edilcek
    
    CONSTRAINT "receteDetayPK" PRIMARY KEY ("receteId", "ilacId"),
    
    CONSTRAINT "rdReceteFK" FOREIGN KEY ("receteId") 
        REFERENCES "randevular"."Recete" ("receteId") 
        ON DELETE CASCADE,
        
    CONSTRAINT "rdIlacFK" FOREIGN KEY ("ilacId") 
        REFERENCES "randevular"."Ilaclar" ("barkod") 
        ON DELETE CASCADE
);

CREATE TABLE "randevular"."Odeme" (
    "odemeId" SERIAL NOT NULL,
    "randevuId" INT NOT NULL,
    "muayeneId" INT,
    "veznedarId" INT NOT NULL,
    "tutar" DECIMAL(10, 2) NOT NULL,
    "odemeTarihi" TIMESTAMP DEFAULT CURRENT_TIMESTAMP, --işlem tarihini otomatik işlemin yapıldığı tarih yapar
    
    CONSTRAINT "odemePK" PRIMARY KEY ("odemeId"),
    
    CONSTRAINT "oRandevuFK" FOREIGN KEY ("randevuId") 
        REFERENCES "randevular"."Randevu" ("randevuId") 
        ON DELETE CASCADE,
    
    CONSTRAINT "oMuayeneFK" FOREIGN KEY ("muayeneId") 
        REFERENCES "randevular"."Muayene" ("muayeneId") 
        ON DELETE CASCADE,
        
    CONSTRAINT "oVeznedarFK" FOREIGN KEY ("veznedarId") 
        REFERENCES "vatandas"."Personel" ("personelId") 
        ON DELETE CASCADE,
    
    CONSTRAINT "odemeUnique" UNIQUE ("muayeneId")
);


--FONKSİYONLAR

CREATE OR REPLACE FUNCTION "randevular"."fn_CiroGuncelle"()
RETURNS TRIGGER AS '
DECLARE
    v_hastaneId INT;
BEGIN
    SELECT p."hastaneId" INTO v_hastaneId
    FROM "randevular"."Randevu" r
    INNER JOIN "iller"."Poliklinik" p ON r."poliklinikId" = p."poliklinikId"
    WHERE r."randevuId" = NEW."randevuId" -- Artık randevuId üzerinden buluyoruz
    LIMIT 1;

    IF v_hastaneId IS NOT NULL THEN
        UPDATE "iller"."Hastane"
        SET "toplamCiro" = COALESCE("toplamCiro", 0) + NEW."tutar"
        WHERE "hastaneId" = v_hastaneId;
    END IF;

    RETURN NEW;
END;
' LANGUAGE plpgsql;

-- Doktor Arama
CREATE OR REPLACE FUNCTION "vatandas"."fn_DoktorAra" (p_uzmanlik VARCHAR)
RETURNS TABLE ("AdSoyad" VARCHAR, "HastaneAdi" VARCHAR) AS '
    SELECT (v."ad" || '' '' || v."soyad")::VARCHAR, h."hastaneAdi"
    FROM "vatandas"."Doktor" d
    JOIN "vatandas"."Vatandas" v ON d."doktorId" = v."vatandasId"
    JOIN "vatandas"."HastanePersonel" hp ON d."doktorId" = hp."personelId"
    JOIN "iller"."Hastane" h ON hp."hastaneId" = h."hastaneId"
    WHERE d."uzmanlikAlani" ILIKE ''%'' || p_uzmanlik || ''%''
' LANGUAGE SQL;

-- Hasta Geçmişi
CREATE OR REPLACE FUNCTION "randevular"."fn_HastaGecmisi" (p_tc BIGINT)
RETURNS TABLE ("Tarih" TIMESTAMP, "Tani" TEXT) AS '
    SELECT r."randevuTarihi", m."tani"
    FROM "vatandas"."Vatandas" v
    JOIN "vatandas"."Hasta" h ON v."vatandasId" = h."hastaId"
    JOIN "randevular"."Randevu" r ON h."hastaId" = r."hastaId"
    JOIN "randevular"."Muayene" m ON r."randevuId" = m."randevuId"
    WHERE v."tcKimlikNo" = p_tc
' LANGUAGE SQL;

-- İlaç Sayısı
CREATE OR REPLACE FUNCTION "randevular"."fn_ReceteIlacSayisi" (p_receteId INT)
RETURNS INT AS '
    SELECT COUNT(*)::INT 
    FROM "randevular"."ReceteDetay" 
    WHERE "receteId" = p_receteId
' LANGUAGE SQL;

-- Hastane Ciro Hesapla
CREATE OR REPLACE FUNCTION "randevular"."fn_HastaneCiroHesapla"(p_hastaneId INT)
RETURNS DECIMAL(10,2) AS '
DECLARE
    toplamCiro DECIMAL(10,2);
BEGIN
    SELECT COALESCE(SUM(o."tutar"), 0)
    INTO toplamCiro
    FROM "randevular"."Odeme" o
    INNER JOIN "randevular"."Randevu" r ON o."randevuId" = r."randevuId"
    INNER JOIN "iller"."Poliklinik" p ON r."poliklinikId" = p."poliklinikId"
    WHERE p."hastaneId" = p_hastaneId;

    RETURN toplamCiro;
END;
' LANGUAGE plpgsql;

--TRIGGERLAR

CREATE TRIGGER "trg_OdemeYapildi"
AFTER INSERT ON "randevular"."Odeme"
FOR EACH ROW
EXECUTE FUNCTION "randevular"."fn_CiroGuncelle"();

-- Oda Kapasite
CREATE OR REPLACE FUNCTION "randevular"."trg_OdaKapasite_Func"() RETURNS TRIGGER AS '
DECLARE mevcut INT; kapasite INT; BEGIN
 SELECT "kapasite" INTO kapasite FROM "iller"."Oda" WHERE "hastaneId"=NEW."hastaneId" AND "odaNo"=NEW."odaNo";
 SELECT COUNT(*) INTO mevcut FROM "randevular"."Yatis" WHERE "hastaneId"=NEW."hastaneId" AND "odaNo"=NEW."odaNo" AND "taburcuTarihi" IS NULL;
 IF mevcut >= kapasite THEN RAISE EXCEPTION ''HATA: Oda dolu! Kapasite aşıldı.''; END IF;
 RETURN NEW;
END; ' LANGUAGE plpgsql;

-- Geçmiş Tarih 
CREATE OR REPLACE FUNCTION "randevular"."trg_RandevuTarih_Func"() RETURNS TRIGGER AS '
BEGIN IF NEW."randevuTarihi" < NOW() THEN RAISE EXCEPTION ''HATA: Geçmişe randevu verilemez!''; END IF; RETURN NEW; END;
' LANGUAGE plpgsql;

-- Loglama 
CREATE OR REPLACE FUNCTION "randevular"."trg_RandevuLog_Func"() RETURNS TRIGGER AS '
BEGIN INSERT INTO "randevular"."RandevuIptalLog" ("randevuId", "hastaId", "doktorId") VALUES (OLD."randevuId", OLD."hastaId", OLD."doktorId"); RETURN OLD; END;
' LANGUAGE plpgsql;

-- Adet Kontrol 
CREATE OR REPLACE FUNCTION "randevular"."trg_ReceteAdet_Func"() RETURNS TRIGGER AS '
BEGIN IF NEW."adet" <= 0 THEN RAISE EXCEPTION ''HATA: Adet 0 dan büyük olmalı!''; END IF; RETURN NEW; END;
' LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS "trg_OdaKapasite" ON "randevular"."Yatis";
CREATE TRIGGER "trg_OdaKapasite" BEFORE INSERT ON "randevular"."Yatis"
FOR EACH ROW EXECUTE FUNCTION "randevular"."trg_OdaKapasite_Func"();

DROP TRIGGER IF EXISTS "trg_RandevuTarih" ON "randevular"."Randevu";
CREATE TRIGGER "trg_RandevuTarih" BEFORE INSERT ON "randevular"."Randevu"
FOR EACH ROW EXECUTE FUNCTION "randevular"."trg_RandevuTarih_Func"();

DROP TRIGGER IF EXISTS "trg_RandevuLog" ON "randevular"."Randevu";
CREATE TRIGGER "trg_RandevuLog" AFTER DELETE ON "randevular"."Randevu"
FOR EACH ROW EXECUTE FUNCTION "randevular"."trg_RandevuLog_Func"();

DROP TRIGGER IF EXISTS "trg_ReceteAdet" ON "randevular"."ReceteDetay";
CREATE TRIGGER "trg_ReceteAdet" BEFORE INSERT OR UPDATE ON "randevular"."ReceteDetay"
FOR EACH ROW EXECUTE FUNCTION "randevular"."trg_ReceteAdet_Func"();







TRUNCATE TABLE "randevular"."ReceteDetay" CASCADE;
TRUNCATE TABLE "randevular"."Recete" CASCADE;
TRUNCATE TABLE "randevular"."Muayene" CASCADE;
TRUNCATE TABLE "randevular"."Randevu" CASCADE;
TRUNCATE TABLE "randevular"."Ilaclar" CASCADE;
TRUNCATE TABLE "randevular"."RandevuIptalLog" CASCADE;
TRUNCATE TABLE "randevular"."Odeme" CASCADE;
TRUNCATE TABLE "vatandas"."HastanePersonel" CASCADE;
TRUNCATE TABLE "iller"."Poliklinik" CASCADE;
TRUNCATE TABLE "iller"."PoliklinikTuru" CASCADE;
TRUNCATE TABLE "iller"."Hastane" CASCADE;
TRUNCATE TABLE "iller"."Iller" CASCADE;
TRUNCATE TABLE "vatandas"."Doktor" CASCADE;
TRUNCATE TABLE "vatandas"."Personel" CASCADE;
TRUNCATE TABLE "vatandas"."Vatandas" CASCADE;

INSERT INTO "iller"."Iller" ("ilPlaka", "ilAdi") VALUES (6, 'Ankara');
INSERT INTO "iller"."Iller" ("ilPlaka", "ilAdi") VALUES (34, 'İstanbul');

INSERT INTO "iller"."Hastane" ("hastaneId", "hastaneAdi", "ilPlaka") VALUES (1, 'Ankara Şehir Hastanesi', 6);
INSERT INTO "iller"."Hastane" ("hastaneId", "hastaneAdi", "ilPlaka") VALUES (2, 'İstanbul Şehir Hastanesi', 34);

INSERT INTO "iller"."PoliklinikTuru" ("turId", "turAdi") VALUES (1, 'Kardiyoloji');
INSERT INTO "iller"."PoliklinikTuru" ("turId", "turAdi") VALUES (2, 'Dahiliye');
INSERT INTO "iller"."PoliklinikTuru" ("turId", "turAdi") VALUES (3, 'Göz Hastalıkları');
INSERT INTO "iller"."PoliklinikTuru" ("turId", "turAdi") VALUES (4, 'Kulak Burun Boğaz');

INSERT INTO "iller"."Poliklinik" ("poliklinikId", "hastaneId", "turId") VALUES (1, 1, 1);
INSERT INTO "iller"."Poliklinik" ("poliklinikId", "hastaneId", "turId") VALUES (2, 1, 2);
INSERT INTO "iller"."Poliklinik" ("poliklinikId", "hastaneId", "turId") VALUES (3, 2, 3);
INSERT INTO "iller"."Poliklinik" ("poliklinikId", "hastaneId", "turId") VALUES (4, 2, 4);

INSERT INTO "vatandas"."Vatandas" ("vatandasId", "tcKimlikNo", "ad", "soyad", "adres") VALUES (1, 11111111111, 'Ali', 'Yılmaz', 'Çankaya/Ankara');
INSERT INTO "vatandas"."Personel" ("personelId", "gorevTuru", "unvan", "sicilNo", "sifre") VALUES (1, 'Doktor', 'Prof. Dr.', 'DR-101', '1234');
INSERT INTO "vatandas"."Doktor" ("doktorId", "uzmanlikAlani") VALUES (1, 'Kardiyoloji');
INSERT INTO "vatandas"."HastanePersonel" ("hastanePersonelId", "personelId", "hastaneId") VALUES (1, 1, 1);

INSERT INTO "vatandas"."Vatandas" ("vatandasId", "tcKimlikNo", "ad", "soyad", "adres") VALUES (2, 22222222222, 'Zeynep', 'Kaya', 'Keçiören/Ankara');
INSERT INTO "vatandas"."Personel" ("personelId", "gorevTuru", "unvan", "sicilNo", "sifre") VALUES (2, 'Doktor', 'Op. Dr.', 'DR-102', '1234');
INSERT INTO "vatandas"."Doktor" ("doktorId", "uzmanlikAlani") VALUES (2, 'Dahiliye');
INSERT INTO "vatandas"."HastanePersonel" ("hastanePersonelId", "personelId", "hastaneId") VALUES (2, 2, 1);

INSERT INTO "vatandas"."Vatandas" ("vatandasId", "tcKimlikNo", "ad", "soyad", "adres") VALUES (3, 33333333333, 'Ahmet', 'Demir', 'Mamak/Ankara');
INSERT INTO "vatandas"."Personel" ("personelId", "gorevTuru", "unvan", "sicilNo", "sifre") VALUES (3, 'Sekreter', 'Tıbbi Sekreter', 'SEK-001', '1234');
INSERT INTO "vatandas"."HastanePersonel" ("hastanePersonelId", "personelId", "hastaneId") VALUES (3, 3, 1);

INSERT INTO "vatandas"."Vatandas" ("vatandasId", "tcKimlikNo", "ad", "soyad", "adres") VALUES (4, 44444444444, 'Seda', 'Yıldız', 'Batıkent/Ankara');
INSERT INTO "vatandas"."Personel" ("personelId", "gorevTuru", "unvan", "sicilNo", "sifre") VALUES (4, 'Sekreter', 'Danışma', 'SEK-002', '1234');
INSERT INTO "vatandas"."HastanePersonel" ("hastanePersonelId", "personelId", "hastaneId") VALUES (4, 4, 1);

INSERT INTO "vatandas"."Vatandas" ("vatandasId", "tcKimlikNo", "ad", "soyad", "adres") VALUES (5, 55555555555, 'Burak', 'Can', 'Başakşehir/İstanbul');
INSERT INTO "vatandas"."Personel" ("personelId", "gorevTuru", "unvan", "sicilNo", "sifre") VALUES (5, 'Doktor', 'Uzm. Dr.', 'DR-201', '1234');
INSERT INTO "vatandas"."Doktor" ("doktorId", "uzmanlikAlani") VALUES (5, 'Göz Hastalıkları');
INSERT INTO "vatandas"."HastanePersonel" ("hastanePersonelId", "personelId", "hastaneId") VALUES (5, 5, 2);

INSERT INTO "vatandas"."Vatandas" ("vatandasId", "tcKimlikNo", "ad", "soyad", "adres") VALUES (6, 66666666666, 'Elif', 'Şahin', 'Fatih/İstanbul');
INSERT INTO "vatandas"."Personel" ("personelId", "gorevTuru", "unvan", "sicilNo", "sifre") VALUES (6, 'Doktor', 'Op. Dr.', 'DR-202', '1234');
INSERT INTO "vatandas"."Doktor" ("doktorId", "uzmanlikAlani") VALUES (6, 'Kulak Burun Boğaz');
INSERT INTO "vatandas"."HastanePersonel" ("hastanePersonelId", "personelId", "hastaneId") VALUES (6, 6, 2);

INSERT INTO "randevular"."Ilaclar" ("barkod", "ilacAdi") VALUES (8699501, 'Parol');
INSERT INTO "randevular"."Ilaclar" ("barkod", "ilacAdi") VALUES (8699502, 'Aspirin');
INSERT INTO "randevular"."Ilaclar" ("barkod", "ilacAdi") VALUES (8699503, 'Augmentin');
INSERT INTO "randevular"."Ilaclar" ("barkod", "ilacAdi") VALUES (8699504, 'Majezik');
INSERT INTO "randevular"."Ilaclar" ("barkod", "ilacAdi") VALUES (8699505, 'Arveles');
INSERT INTO "randevular"."Ilaclar" ("barkod", "ilacAdi") VALUES (8699506, 'Dikloron');
INSERT INTO "randevular"."Ilaclar" ("barkod", "ilacAdi") VALUES (8699507, 'Dolorex');
INSERT INTO "randevular"."Ilaclar" ("barkod", "ilacAdi") VALUES (8699508, 'Nurofen');
INSERT INTO "randevular"."Ilaclar" ("barkod", "ilacAdi") VALUES (8699509, 'Gripin');
INSERT INTO "randevular"."Ilaclar" ("barkod", "ilacAdi") VALUES (8699510, 'Vermidon');

SELECT setval(pg_get_serial_sequence('"vatandas"."Vatandas"', 'vatandasId'), (SELECT MAX("vatandasId") FROM "vatandas"."Vatandas"));
SELECT setval(pg_get_serial_sequence('"iller"."Hastane"', 'hastaneId'), (SELECT MAX("hastaneId") FROM "iller"."Hastane"));
SELECT setval(pg_get_serial_sequence('"iller"."Poliklinik"', 'poliklinikId'), (SELECT MAX("poliklinikId") FROM "iller"."Poliklinik"));
SELECT setval(pg_get_serial_sequence('"vatandas"."HastanePersonel"', 'hastanePersonelId'), (SELECT MAX("hastanePersonelId") FROM "vatandas"."HastanePersonel"));









