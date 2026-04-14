namespace ApartmanWeb.Models;

public class ArizaDto
{
    public int Id { get; set; }
    public string Baslik { get; set; } = string.Empty;
    public string? Aciklama { get; set; }
    public string Durum { get; set; } = "Beklemede";
    public string Oncelik { get; set; } = "Orta";
    public DateTime Tarih { get; set; }
    public string? BildirenDaireNo { get; set; }
    public int BildirenId { get; set; }
    public string? BildirenAdSoyad { get; set; }
}

public class ArizaFotoDto
{
    public int Id { get; set; }
    public string Url { get; set; } = string.Empty;
}

public class ArizaDetayViewModel
{
    public ArizaDto Ariza { get; set; } = new();
    public List<ArizaFotoDto> Fotograflar { get; set; } = new();
}

public class ArizaCreateRequest
{
    public int BildirenId { get; set; }
    public string Baslik { get; set; } = string.Empty;
    public string Aciklama { get; set; } = string.Empty;
    public string Oncelik { get; set; } = "Orta";
}
