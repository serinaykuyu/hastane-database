DROP TABLE IF EXISTS "iller"."Oda" CASCADE;
DROP TABLE IF EXISTS "iller"."Poliklinik" CASCADE;
DROP TABLE IF EXISTS "iller"."Hastane" CASCADE;
DROP TABLE IF EXISTS "iller"."PoliklinikTuru" CASCADE;
DROP TABLE IF EXISTS "iller"."Iller" CASCADE;
DROP TABLE IF EXISTS "vatandas"."Doktor" CASCADE;
DROP TABLE IF EXISTS "vatandas"."Personel" CASCADE;
DROP TABLE IF EXISTS "vatandas"."Vatandas" CASCADE;
DROP TABLE IF EXISTS "vatandas"."Hasta" CASCADE;
DROP TABLE IF EXISTS "vatandas"."HastaYakini" CASCADE;
DROP TABLE IF EXISTS "vatandas"."HastanePersonel" CASCADE;
DROP TABLE IF EXISTS "randevular"."Randevu" CASCADE;
DROP TABLE IF EXISTS "randevular"."Muayene" CASCADE;
DROP TABLE IF EXISTS "randevular"."Tahlil" CASCADE;
DROP TABLE IF EXISTS "randevular"."Recete" CASCADE;
DROP TABLE IF EXISTS "randevular"."Ilaclar" CASCADE;
DROP TABLE IF EXISTS "randevular"."ReceteDetay" CASCADE;
DROP TABLE IF EXISTS "randevular"."Odeme" CASCADE;


CREATE SCHEMA IF NOT EXISTS "iller";
CREATE SCHEMA IF NOT EXISTS "vatandas";
CREATE SCHEMA IF NOT EXISTS "randevular";


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
    "barkod" INT NOT NULL,
    "ilacAdi" VARCHAR(50) NOT NULL,
    
    CONSTRAINT "ilaclarPK" PRIMARY KEY ("barkod")
);

CREATE TABLE "randevular"."ReceteDetay" (
    "receteId" INT NOT NULL,
    "ilacId" INT NOT NULL,
    "kullanımDozu" INT NOT NULL,
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
    "tutar" INT NOT NULL,
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
