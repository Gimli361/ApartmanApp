namespace ApartmanWeb.Models;

public class DashboardViewModel
{
    public int ToplamSakin { get; set; }
    public int BekleyenAriza { get; set; }
    public int OdenmemisAidat { get; set; }
    public int KritikAriza { get; set; }
    public List<ArizaDto> SonArizalar { get; set; } = new();
}
