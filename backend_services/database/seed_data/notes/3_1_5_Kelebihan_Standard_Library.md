# 3.1.5 Kelebihan Standard Library

**Standard Library** dalam pengaturcaraan merupakan koleksi kaedah atau fungsi yang disediakan dan diguna pakai sewaktu implementasi dalam kod atur cara. Ia perlu ditakrifkan dalam spesifikasi bahasa pengaturcaraan dan merangkumi definisi bagi algoritma, struktur data, dan mekanisme input/output.

### Contoh Standard Library dalam JavaScript:
* `math.js`: Untuk fungsi matematik seperti `math.sqrt()` (punca kuasa) dan `math.pow()` (kuasa).
* `date.js`: Untuk fungsi tarikh seperti `date.now()` dan `date.format()`.

### Kelebihan Standard Library:
1.  **Kemudahan Penggunaan:** Boleh digunakan tanpa mengetahui cara pelaksanaan dalaman yang kompleks. Contohnya, `math.pow()` boleh dipanggil tanpa perlu memprogramkan operasi kiraan kuasa secara manual.
2.  **Kebolehgunaan Semula:** Boleh digunakan berulang kali dalam atur cara dengan hanya memanggil fungsinya.
3.  **Penjimatan Masa:** Mengurangkan masa pembangunan kerana tidak perlu menulis pernyataan yang sama berulang kali.

---
### Contoh Atur Cara JavaScript (math.js):
```html
<html>
<head>
<script src="math.js"></script>
</head>
<body>
<script>
document.write("Punca kuasa dua bagi 4 ialah ", math.sqrt(4));
document.write("<br>3 kuasa 2 ialah ", math.pow(3, 2));
</script>
</body>
</html>