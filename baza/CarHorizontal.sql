USE CarHorizontal;
GO

-- ==========================================
-- 1. dio korisnici
-- ==========================================

CREATE TABLE Uloge (
    UlogaID INT IDENTITY(1,1) PRIMARY KEY,
    NazivUloge NVARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Korisnici (
    KorisnikID INT IDENTITY(1,1) PRIMARY KEY,
    Ime NVARCHAR(50) NOT NULL,
    Prezime NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    Lozinka NVARCHAR(255) NOT NULL,
    UlogaID INT FOREIGN KEY REFERENCES Uloge(UlogaID),
    DatumRegistracije DATETIME DEFAULT GETDATE()
);

CREATE TABLE ProfiliKorisnika (
    ProfilID INT IDENTITY(1,1) PRIMARY KEY,
    KorisnikID INT UNIQUE FOREIGN KEY REFERENCES Korisnici(KorisnikID) ON DELETE CASCADE,
    BrojTelefona NVARCHAR(20),
    Grad NVARCHAR(50),
    Drzava NVARCHAR(50)
);

-- ==========================================
-- 2. dio podaci o vozilima
-- ==========================================

CREATE TABLE Vozila (
    VoziloID INT IDENTITY(1,1) PRIMARY KEY,
    VIN NVARCHAR(17) NOT NULL UNIQUE,
    Marka NVARCHAR(50) NOT NULL,
    Model NVARCHAR(50) NOT NULL,
    Godiste INT NOT NULL,
    Kubikaza INT,
    SnagaKS INT,
    Gorivo NVARCHAR(20)
);

CREATE TABLE IstorijaVlasnika (
    VlasnikID INT IDENTITY(1,1) PRIMARY KEY,
    VoziloID INT FOREIGN KEY REFERENCES Vozila(VoziloID) ON DELETE CASCADE,
    TipVlasnika NVARCHAR(30), 
    ZemljaRegistracije NVARCHAR(50),
    DatumOd DATETIME,
    DatumDo DATETIME
);

CREATE TABLE StatusPotrage (
    PotragaID INT IDENTITY(1,1) PRIMARY KEY,
    VoziloID INT UNIQUE FOREIGN KEY REFERENCES Vozila(VoziloID) ON DELETE CASCADE,
    IsUkraden BIT DEFAULT 0,
    DrzavaPrijave NVARCHAR(50),
    DatumPrijave DATETIME
);

-- ==========================================
-- 3. dio istorija vozila i logsss
-- ==========================================

CREATE TABLE ZapisiKilometraze (
    ZapisID INT IDENTITY(1,1) PRIMARY KEY,
    VoziloID INT FOREIGN KEY REFERENCES Vozila(VoziloID) ON DELETE CASCADE,
    Kilometraza INT NOT NULL,
    DatumZapisa DATETIME NOT NULL,
    IzvorZapisa NVARCHAR(50)
);

CREATE TABLE ServisnaIstorija (
    ServisID INT IDENTITY(1,1) PRIMARY KEY,
    VoziloID INT FOREIGN KEY REFERENCES Vozila(VoziloID) ON DELETE CASCADE,
    OpisServisa NVARCHAR(MAX) NOT NULL,
    CijenaServisa DECIMAL(10,2),
    DatumServisa DATETIME NOT NULL,
    NazivServisa NVARCHAR(100)
);

CREATE TABLE ZapisiNesreca (
    NesrecaID INT IDENTITY(1,1) PRIMARY KEY,
    VoziloID INT FOREIGN KEY REFERENCES Vozila(VoziloID) ON DELETE CASCADE,
    DatumNesrece DATETIME NOT NULL,
    OpisOstecenja NVARCHAR(MAX) NOT NULL,
    ProcijenjenaStetaEVR DECIMAL(10,2)
);

CREATE TABLE KupljeniIzvjestaji (
    IzvjestajID INT IDENTITY(1,1) PRIMARY KEY,
    KorisnikID INT FOREIGN KEY REFERENCES Korisnici(KorisnikID),
    VoziloID INT FOREIGN KEY REFERENCES Vozila(VoziloID),
    DatumKupovine DATETIME DEFAULT GETDATE(),
    Cijena DECIMAL(5,2) NOT NULL,
    StatusPlacanja NVARCHAR(20) DEFAULT 'Zavrseno'
);

CREATE TABLE LogoviAktivnosti (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    KorisnikID INT NULL,
    Akcija NVARCHAR(100) NOT NULL,
    OpisAktivnosti NVARCHAR(MAX),
    DatumVrijeme DATETIME DEFAULT GETDATE()
);
GO

-- ==========================================
-- 4. inserts test
-- ==========================================

INSERT INTO Uloge (NazivUloge) VALUES ('Admin'), ('Korisnik');

INSERT INTO Vozila (VIN, Marka, Model, Godiste, Kubikaza, SnagaKS, Gorivo)
VALUES ('WAUZZZ8KGAN123456', 'Audi', 'A4 B9', 2017, 1968, 150, 'Dizel');

INSERT INTO ZapisiKilometraze (VoziloID, Kilometraza, DatumZapisa, IzvorZapisa)
VALUES 
(1, 85000, '2020-03-15', 'Uvoz iz Italije'),
(1, 132000, '2023-05-10', 'Tehnicki pregled'),
(1, 178000, '2026-02-20', 'Redovni servis');

INSERT INTO IstorijaVlasnika (VoziloID, TipVlasnika, ZemljaRegistracije, DatumOd, DatumDo)
VALUES (1, 'Fizicko lice', 'Crna Gora', '2020-04-01', NULL);

INSERT INTO ServisnaIstorija (VoziloID, OpisServisa, CijenaServisa, DatumServisa, NazivServisa)
VALUES (1, 'Zamjena zupcastog kaisa, vodene pumpe i ulja', 450.00, '2024-01-12', 'Auto Servis Vukovic');

INSERT INTO StatusPotrage (VoziloID, IsUkraden) VALUES (1, 0);
GO

-- ==========================================
-- 5. stored procedures
-- ==========================================

CREATE PROCEDURE Sp_BrzaPretragaVozila
    @VIN NVARCHAR(17)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        v.VoziloID, 
        v.Marka, 
        v.Model, 
        v.Godiste, 
        v.Gorivo,
        (SELECT COUNT(*) FROM ZapisiKilometraze WHERE VoziloID = v.VoziloID) AS BrojZapisaKilometraze,
        (SELECT COUNT(*) FROM ServisnaIstorija WHERE VoziloID = v.VoziloID) AS BrojServisa,
        (SELECT COUNT(*) FROM ZapisiNesreca WHERE VoziloID = v.VoziloID) AS BrojNesreca
    FROM Vozila v
    WHERE v.VIN = @VIN;
END;
GO

CREATE PROCEDURE Sp_DetaljnaPretragaVozila
    @Marka NVARCHAR(50) = NULL,
    @Model NVARCHAR(50) = NULL,
    @Gorivo NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT VoziloID, VIN, Marka, Model, Godiste, Gorivo, SnagaKS
    FROM Vozila
    WHERE (@Marka IS NULL OR Marka LIKE '%' + @Marka + '%')
      AND (@Model IS NULL OR Model LIKE '%' + @Model + '%')
      AND (@Gorivo IS NULL OR Gorivo = @Gorivo);
END;
GO

-- ==========================================
-- 6. funkcije
-- ==========================================

CREATE FUNCTION fn_UkupnaStetaNaVozilu (@VoziloID INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Ukupno DECIMAL(10,2);
    
    SELECT @Ukupno = ISNULL(SUM(ProcijenjenaStetaEVR), 0)
    FROM ZapisiNesreca
    WHERE VoziloID = @VoziloID;
    
    RETURN @Ukupno;
END;
GO

CREATE FUNCTION fn_ProvjeriStatusPotrage (@VoziloID INT)
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @Status NVARCHAR(50);
    DECLARE @IsUkraden BIT;

    SELECT @IsUkraden = IsUkraden FROM StatusPotrage WHERE VoziloID = @VoziloID;

    IF @IsUkraden = 1
        SET @Status = 'POTRAGA: VOZILO JE UKRADENO';
    ELSE
        SET @Status = 'Vozilo nije ukradeno';

    RETURN @Status;
END;
GO

-- ==========================================
-- 7. DIO: TRIGERI
-- ==========================================

CREATE TRIGGER trg_LogujBrisanjeVozila
ON Vozila
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO LogoviAktivnosti (KorisnikID, Akcija, OpisAktivnosti, DatumVrijeme)
    SELECT 
        NULL,
        'BRISANJE VOZILA',
        'Obrisano vozilo: ' + d.Marka + ' ' + d.Model + ' (VIN: ' + d.VIN + ')',
        GETDATE()
    FROM Deleted d;
END;
GO

CREATE TRIGGER trg_ProvjeraKilometraze
ON ZapisiKilometraze
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 
        FROM inserted i
        JOIN ZapisiKilometraze zk ON i.VoziloID = zk.VoziloID
        WHERE i.Kilometraza < zk.Kilometraza AND i.ZapisID <> zk.ZapisID
    )
    BEGIN
        RAISERROR ('Greska: Unijeta kilometraza je manja od prethodno zabiljezene!', 16, 1);
        ROLLBACK TRANSACTION;
    END;
END;
GO