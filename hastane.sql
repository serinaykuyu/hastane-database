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
    "muayeneId" INT NOT NULL,
    "veznedarId" INT NOT NULL,
    "tutar" DECIMAL(10, 2) NOT NULL,
    "odemeTarihi" TIMESTAMP DEFAULT CURRENT_TIMESTAMP, --işlem tarihini otomatik işlemin yapıldığı tarih yapar
    
    CONSTRAINT "odemePK" PRIMARY KEY ("odemeId"),
    
    CONSTRAINT "oMuayeneFK" FOREIGN KEY ("muayeneId") 
        REFERENCES "randevular"."Muayene" ("muayeneId") 
        ON DELETE CASCADE,
        
    CONSTRAINT "oVeznedarFK" FOREIGN KEY ("veznedarId") 
        REFERENCES "vatandas"."Personel" ("personelId") 
        ON DELETE CASCADE,
    
    CONSTRAINT "odemeUnique" UNIQUE ("muayeneId")
);


--FONKSİYONLAR

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
CREATE OR REPLACE FUNCTION "randevular"."fn_HastaneCiroHesapla" (p_hastaneId INT)
RETURNS DECIMAL AS '
    SELECT COALESCE(SUM(o."tutar"), 0)
    FROM "randevular"."Odeme" o
    JOIN "randevular"."Muayene" m ON o."muayeneId" = m."muayeneId"
    JOIN "randevular"."Randevu" r ON m."randevuId" = r."randevuId"
    JOIN "iller"."Poliklinik" p ON r."poliklinikId" = p."poliklinikId"
    WHERE p."hastaneId" = p_hastaneId
' LANGUAGE SQL;


--TRIGGERLAR

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



















