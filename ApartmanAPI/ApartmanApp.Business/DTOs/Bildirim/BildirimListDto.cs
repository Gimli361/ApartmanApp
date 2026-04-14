namespace ApartmanApp.Business.DTOs.Bildirim;

public class BildirimListDto
{
    public int Id { get; set; }
    public string Baslik { get; set; } = string.Empty;
    public string Icerik { get; set; } = string.Empty;
    public string Tip { get; set; } = string.Empty;
    public DateTime GonderimTarihi { get; set; }
    public bool Okundu { get; set; }
}
