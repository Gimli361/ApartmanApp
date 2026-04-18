namespace ApartmanApp.Business.DTOs.Oylama;

public class OylamaCreateDto
{
    public string Baslik { get; set; } = string.Empty;
    public string? Aciklama { get; set; }
    public DateTime BitisTarihi { get; set; }
    public List<string> Secenekler { get; set; } = [];
}
