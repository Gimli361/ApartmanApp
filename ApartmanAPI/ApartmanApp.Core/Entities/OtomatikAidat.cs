namespace ApartmanApp.Core.Entities;

public class OtomatikAidat
{
    public int Id { get; set; }
    public int KullaniciId { get; set; }
    public decimal Tutar { get; set; }
    public bool AktifMi { get; set; } = true;

    // Son üretim bilgisi — aynı ay tekrar oluşturulmasın
    public int? SonUretimAy { get; set; }
    public int? SonUretimYil { get; set; }

    // Navigation
    public Kullanici Kullanici { get; set; } = null!;
}
