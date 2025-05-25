-- Membuat database
CREATE DATABASE restoran_7;
USE restoran_7;

-- Membuat tabel Menu (Master)
CREATE TABLE Menu (
    id_menu INT AUTO_INCREMENT PRIMARY KEY,
    nama_menu VARCHAR(100) NOT NULL,
    kategori ENUM('Makanan', 'Minuman') NOT NULL,
    harga DECIMAL(10,2) NOT NULL,
    stok INT NOT NULL,
    deskripsi TEXT
);

-- Membuat tabel Pelanggan (Master)
CREATE TABLE Pelanggan (
    id_pelanggan INT AUTO_INCREMENT PRIMARY KEY,
    nama VARCHAR(100) NOT NULL,
    no_hp VARCHAR(15) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE,
    alamat TEXT
);

-- Membuat tabel Karyawan (Master)
CREATE TABLE Karyawan (
    id_karyawan INT AUTO_INCREMENT PRIMARY KEY,
    nama VARCHAR(100) NOT NULL,
    jabatan ENUM('Kasir', 'Pelayan', 'Koki') NOT NULL,
    no_hp VARCHAR(15) UNIQUE NOT NULL
);

-- Membuat tabel Pesanan (Transaksi)
CREATE TABLE Pesanan (
    id_pesanan INT AUTO_INCREMENT PRIMARY KEY,
    id_pelanggan INT NOT NULL,
    id_karyawan INT, -- dibuat NULLABLE karena pakai ON DELETE SET NULL
    tanggal DATETIME DEFAULT CURRENT_TIMESTAMP,
    total_harga DECIMAL(10,2) NOT NULL,
    STATUS ENUM('Belum Dibayar', 'Lunas') DEFAULT 'Belum Dibayar',
    FOREIGN KEY (id_pelanggan) REFERENCES Pelanggan(id_pelanggan) ON DELETE CASCADE,
    FOREIGN KEY (id_karyawan) REFERENCES Karyawan(id_karyawan) ON DELETE SET NULL
);


-- Membuat tabel Detail_Pesanan (Transaksi)
CREATE TABLE Detail_Pesanan (
    id_detail INT AUTO_INCREMENT PRIMARY KEY,
    id_pesanan INT NOT NULL,
    id_menu INT NOT NULL,
    jumlah INT NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_pesanan) REFERENCES Pesanan(id_pesanan) ON DELETE CASCADE,
    FOREIGN KEY (id_menu) REFERENCES Menu(id_menu) ON DELETE CASCADE
);

-- Menambahkan data untuk tabel Menu (Master)
INSERT INTO Menu (nama_menu, kategori, harga, stok, deskripsi) VALUES
('Nasi Goreng Seafood', 'Makanan', 30000, 25, 'Nasi goreng dengan seafood pilihan'),
('Mie Goreng Spesial', 'Makanan', 22000, 18, 'Mie goreng dengan ayam, bakso, dan telur'),
('Teh Tawar', 'Minuman', 3000, 40, 'Teh tawar tanpa gula'),
('Jus Jeruk', 'Minuman', 10000, 15, 'Jus jeruk segar dengan pulp'),
('Kopi Hitam', 'Minuman', 8000, 10, 'Kopi hitam dengan cita rasa pahit khas');

-- Menambahkan data untuk tabel Pelanggan (Master)
INSERT INTO Pelanggan (nama, no_hp, email, alamat) VALUES
('Dewi Putri', '081234567891', 'dewi@gmail.com', 'Jl. Suka No.8'),
('Joko Santoso', '081987654321', 'joko@ymail.com', 'Jl. Satria No.7'),
('Maya Arista', '081122334455', 'maya@gmail.com', 'Jl. Indah No.11'),
('Toni Pratama', '081334455667', 'toni@outlook.com', 'Jl. Merdeka No.30'),
('Andi J', '081234567890', 'Andi@gmail.com', 'Jl. Merdeka No. 10' );

-- Menambahkan data untuk tabel Karyawan (Master)
INSERT INTO Karyawan (nama, jabatan, no_hp) VALUES
('Joni Hidayat', 'Kasir', '081212123123'),
('Fauzan Ridwan', 'Pelayan', '081223234234'),
('Dewi Lestari', 'Koki', '081234345345');

-- Menambahkan data untuk tabel Pesanan (Transaksi)
INSERT INTO Pesanan (id_pelanggan, id_karyawan, total_harga, STATUS) VALUES
(1, 1, 70000, 'Lunas'),
(2, 2, 25000, 'Belum Dibayar'),
(3, NULL, 15000, 'Lunas'),
(4, 3, 10000, 'Lunas');

-- Menambahkan data untuk tabel Detail_Pesanan (Transaksi)
INSERT INTO Detail_Pesanan (id_pesanan, id_menu, jumlah, subtotal) VALUES
(1, 1, 1, 30000),
(1, 3, 2, 14000),
(2, 2, 1, 22000),
(3, 4, 1, 10000),
(4, 5, 1, 8000);

-- Menambahkan transaksi lebih dari 1 tahun
INSERT INTO Pesanan (id_pelanggan, id_karyawan, total_harga, STATUS, tanggal) VALUES
(2, 2, 20000, 'Lunas', '2023-03-10 10:00:00'),
(3, 1, 40000, 'Belum Dibayar', '2022-05-15 08:30:00');

1. Memastikan harga dan stok menu tidak bernilai negatif saat menambahkan DATA ke tabel Menu.

DELIMITER //
CREATE TRIGGER before_insert_menu
BEFORE INSERT ON Menu
FOR EACH ROW
BEGIN
    IF NEW.harga < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Harga tidak boleh negatif!';
    END IF;
    IF NEW.stok < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stok tidak boleh negatif!';
    END IF;
END //
DELIMITER ;

INSERT INTO Menu (nama_menu, kategori, harga, stok, deskripsi)
VALUES ('Test Menu', 'Makanan', -10000, 10, 'Test gagal harga negatif');

INSERT INTO Menu (nama_menu, kategori, harga, stok, deskripsi)
VALUES ('Test Menu', 'Makanan', 10000, -10, 'Test gagal stok negatif');


2. Cegah perubahan STATUS pesanan menjadi Lunas jika total_harga = 0.

DELIMITER //

CREATE TRIGGER before_update_pesanan
BEFORE UPDATE ON Pesanan
FOR EACH ROW

BEGIN
    IF NEW.STATUS = 'Lunas' AND NEW.total_harga = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Total harga tidak boleh 0 untuk status Lunas!';
    END IF;
    
END//
DELIMITER ;

UPDATE Pesanan SET STATUS = 'Lunas', total_harga = 0 WHERE id_pesanan = 2;


3. Cegah penghapusan karyawan dengan jabatan “Kasir”.

DELIMITER //

CREATE TRIGGER before_delete_karyawan
BEFORE DELETE ON Karyawan
FOR EACH ROW

BEGIN
    IF OLD.jabatan = 'Kasir' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Karyawan dengan jabatan Kasir tidak boleh dihapus!';
    END IF;
    
END //
DELIMITER ;

DELETE FROM Karyawan WHERE jabatan = 'Kasir';


4. Catat LOG saat DATA pesanan baru ditambahkan.

CREATE TABLE Log_Pesanan (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    id_pesanan INT,
    aksi VARCHAR(50),
    waktu TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //

CREATE TRIGGER after_insert_pesanan
AFTER INSERT ON Pesanan
FOR EACH ROW

BEGIN
    INSERT INTO Log_Pesanan (id_pesanan, aksi) VALUES (NEW.id_pesanan, 'Pesanan Ditambahkan');
END //
DELIMITER ;

INSERT INTO Pesanan (id_pelanggan, id_karyawan, total_harga, STATUS)
VALUES (5, 2, 50000, 'Belum Dibayar');

SELECT * FROM Log_Pesanan ORDER BY waktu DESC;


5. Catat LOG jika STATUS pesanan berubah.
DELIMITER //

CREATE TRIGGER after_update_status_pesanan
AFTER UPDATE ON Pesanan
FOR EACH ROW

BEGIN
    IF OLD.STATUS <> NEW.STATUS THEN
        INSERT INTO Log_Pesanan (id_pesanan, aksi) 
        VALUES (NEW.id_pesanan, CONCAT('Status berubah dari ', OLD.STATUS, ' ke ', NEW.STATUS));
    END IF;
    
END //
DELIMITER ;

UPDATE Pesanan SET STATUS = 'Lunas' WHERE id_pesanan = 2;

SELECT * FROM Log_Pesanan ORDER BY waktu DESC;


6. Catat LOG penghapusan pesanan.

DELIMITER //

CREATE TRIGGER after_delete_pesanan
AFTER DELETE ON Pesanan
FOR EACH ROW
BEGIN
    INSERT INTO Log_Pesanan (id_pesanan, aksi) 
    VALUES (OLD.id_pesanan, 'Pesanan Dihapus');
    
END //
DELIMITER ;

DELETE FROM Pesanan WHERE id_pesanan = 3;

SELECT * FROM Log_Pesanan ORDER BY waktu DESC;










