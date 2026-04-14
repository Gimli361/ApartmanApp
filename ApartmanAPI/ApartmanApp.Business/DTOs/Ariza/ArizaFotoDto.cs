namespace ApartmanApp.Business.DTOs.Ariza;

public class ArizaFotoDto
{
    public int Id { get; set; }
    public int ArizaId { get; set; }
    public string DosyaAdi { get; set; } = string.Empty;
    public long DosyaBoyutu { get; set; }
    public DateTime YuklemeTarihi { get; set; }
    public string Url { get; set; } = string.Empty;
}
