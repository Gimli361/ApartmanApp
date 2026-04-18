namespace ApartmanWeb.Models;

public class OylamaListDto
{
    public int Id { get; set; }
    public string Baslik { get; set; } = string.Empty;
    public string? Aciklama { get; set; }
    public DateTime BaslangicTarihi { get; set; }
    public DateTime BitisTarihi { get; set; }
    public bool AktifMi { get; set; }
    public int ToplamOySayisi { get; set; }
    public bool KullaniciOyKullandi { get; set; }

    public bool SuresiDoldu => BitisTarihi < DateTime.UtcNow;
    public bool AcikMi => AktifMi && !SuresiDoldu;
}

public class OylamaDetailDto
{
    public int Id { get; set; }
    public string Baslik { get; set; } = string.Empty;
    public string? Aciklama { get; set; }
    public DateTime BaslangicTarihi { get; set; }
    public DateTime BitisTarihi { get; set; }
    public bool AktifMi { get; set; }
    public int OlusturanId { get; set; }
    public int ToplamOySayisi { get; set; }
    public bool KullaniciOyKullandi { get; set; }
    public int? KullaniciSecenekId { get; set; }
    public List<OylamaSecenekDto> Secenekler { get; set; } = [];

    public bool SuresiDoldu => BitisTarihi < DateTime.UtcNow;
    public bool AcikMi => AktifMi && !SuresiDoldu;
}

public class OylamaSecenekDto
{
    public int Id { get; set; }
    public string Metin { get; set; } = string.Empty;
    public int OySayisi { get; set; }
    public double OranYuzde { get; set; }
}

public class OylamaCreateRequest
{
    public string Baslik { get; set; } = string.Empty;
    public string? Aciklama { get; set; }
    public DateTime BitisTarihi { get; set; }
    public List<string> Secenekler { get; set; } = [];
}
