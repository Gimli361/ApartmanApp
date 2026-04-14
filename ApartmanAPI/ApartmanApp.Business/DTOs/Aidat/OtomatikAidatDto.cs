namespace ApartmanApp.Business.DTOs.Aidat;

public class OtomatikAidatDto
{
    public int Id { get; set; }
    public int KullaniciId { get; set; }
    public string KullaniciAdSoyad { get; set; } = string.Empty;
    public string DaireNo { get; set; } = string.Empty;
    public decimal Tutar { get; set; }
    public bool AktifMi { get; set; }
    public int? SonUretimAy { get; set; }
    public int? SonUretimYil { get; set; }
}

public class OtomatikAidatUpsertDto
{
    public int KullaniciId { get; set; }
    public decimal Tutar { get; set; }
}

public class OtomatikAidatTutarGuncelleDto
{
    public decimal Tutar { get; set; }
}
