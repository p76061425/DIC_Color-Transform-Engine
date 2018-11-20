#  Color Transform Engine

## Introduction
完成一Color Transform Engine(後文以CTE 表示)的電路設計。本CTE 電路功能有二，將彩色訊號的每個像素(Pixel)之YUV 訊號轉換成RGB 訊號，以及將彩色訊號的每個Pixel 之RGB 訊號轉成YUV 訊號。彩色影像的每個Pixel 是由R(Red)、G(Green)、B(Blue) 三基色分量的強弱組合來決定一個Pixel 的顏色，例如：RGB 三基色分量(R，G，B) => (0，0，0)（即都最弱）時，該Pixel會呈現黑色，當RGB 三基色分量(R，G，B) => (255，255，255)（即都最強）時，該Pixel會呈現白色，因此調整RGB 三基色分量的值，可以調出各式各樣的顏色。基於不同的應用，彩色影像的另一種表示方法是由YUV 模型表示，其中Y 為明亮度訊號(Luminance)，U 為色調(Hue)，V 為飽和度(Saturation)。RGB 彩色模型與YUV 彩色模型之間關係可以用矩陣(Matrix)型態描述，彼此之間可以互作轉換。YUV 模型特色為，一張影像各Pixel 只需單獨的Y 訊號分量即可決定出一張灰階影像，至於與顏色有關的U、V 訊號，會依其分量的強弱來決定該影像之各Pixel 的色彩。人眼對於彩色訊號之敏銳度較差，因此對於每個Pixel的彩色訊號常會使用次取樣(Down Sample)的機制，以節省記憶空間或減少資料的傳送量。</br>

YUV 彩色模型轉換成 RGB 彩色模型，其矩陣表示式如(1)式。本 CTE 電路 Function 1 之功能是將 YUV 訊號轉換成 RGB 訊號。</br>
![](https://i.imgur.com/mDPmYuc.png)


YUV 都是8 bits 的一維(1D)輸入訊號，Y、U、V 輸出訊號皆為8bits，其中Y 訊號輸入範圍為0~255 的整數值，U 訊號輸入範圍為-117~+117 的整數值，V 訊號輸入範圍為-111~+111的整數值。Testbench的YUV 輸入訊號已事先針對U、V 訊號作Down Sample 2 之處理，因此Y 訊號假設提供N 筆資料量，則U、V訊號提供為各N/2 筆資料量，Y、U、V 訊號是個別輸入的，其輸入順序採用UYVY 格式，該格式輸入順序如fig. 1.所示。(註：所有負數值，都採用 2 的補數(2's Complement)來表示。)</br>

![](https://i.imgur.com/IdgZhUR.png)


R、G、B 訊號皆為 8bits，Function 1 每次可輸出一個 Pixel，每個 Pixel 是由三個 RGB 訊號所構成，因此合計 24bits，RGB 訊號輸出格式定義如 fig. 2.所示。</br>
* Fig. 2. RGB 訊號輸出格式定義
![](https://i.imgur.com/vWW1D2g.png)

R、G、B 訊號皆為8bits，其R、G、B 個別訊號的輸出值範圍皆為0-255 的整數值，當輸出值小於0，輸出為0，當輸出值大於255，輸出為255，當輸出值為0 到255之間，若有小數部分將採取四捨五入法取到整數，其範例如fig. 3.所
示。 (注意: 四捨五入機制，只有在輸出才做,計算過程中的小數部分請勿任意作四捨五入!)</br>

![](https://i.imgur.com/7PHxhn1.png)

CTE 電路 Function 1 計算的規則如 fig. 4.所訂定，其涵義為，CTE 電路的第一個輸出 Pixel 1，其 R1G1B1 訊號值是用 Y1U1V1 的輸入訊號經由(1)式矩陣運算轉換而來的，同理，第二個輸出為 Pixel 2，其 R2G2B2 訊號值是用 Y2U1V1的輸入訊號經由(1)式矩陣運算轉換而來的，其餘以此類推。</br>

![](https://i.imgur.com/bCa59ft.png)


YUV 轉換成 RGB 訊號時，輸出數值在四捨五入後必須完全符合題目要求，不容許有任何的誤差值發生，Function1 才算正確完成。</br>
RGB 彩色模型轉換成 YUV 彩色模型，其矩陣表示式如(2)式。R、G、B 訊號皆為 8bits，Function 2 每次可輸入一個 Pixel，每個 Pixel 是由三個 RGB 訊號所構成，因此共計 24bits，R、G、B 訊號皆為 8bits，因此題目所提供的 RGB 個別的輸入訊號範圍值為 0-255 的整數值。YUV 都是 8 bits 的一維(1D)輸出訊號，U、V 訊號也採用 Down Sample 為 2 的機制，因此 CTE 電路輸出 U、V 訊號前，需自行作 Down Sample 為 2 的動作(亦即 Y 訊號假設輸出 N 筆資料量，U、V 訊號則會輸出各 N/2 筆的資料量)，Y、U、V 訊號是個別輸出的，其輸出順序採用 UYVY 格式，該格式輸出順序如 fig. 5.所示。</br>

![](https://i.imgur.com/IaBkvtf.png)

Y、U、V 輸出訊號皆為8bits， Y 訊號輸出範圍為0~255 的整數值，U 訊號輸出範圍為-117~+117 的整數值，V 訊號輸出範圍為-111~+111 的整數值，當計算數值超出其輸出範圍時，必須自動修正為範圍邊界值。(註：所有負數
值，都採用 2's Complement 來表示。)</br>

當Y、U、V 訊號的輸出有小數點，處理方法為: </br>
1. 若為正數，採用四捨五入法取到整數。
2. 若為負數，採用五捨六入法取到整數。

![](https://i.imgur.com/7j5IuDO.png)

CTE 電路 Function2 計算的規則如 fig. 7.所訂定，其涵義為，CTE 電路的輸出訊號 Y1U1V1 訊號值，可由R1G1B1 的輸入訊號經由(2)式矩陣運算轉換而來的，而 Y2 訊號值可由 R2G2B2 的輸入訊號經由(2)式矩陣運算轉換而來，其餘的 YUV 訊號依此類推。由於(2)式矩陣中的係數皆為循環小數，因此轉換成YUV 訊號時，可容許有誤差值的發生，但其誤差值與 Golden Pattern 比對差異越大者，分數將會越低分。</br>

![](https://i.imgur.com/nZBOzik.png)
