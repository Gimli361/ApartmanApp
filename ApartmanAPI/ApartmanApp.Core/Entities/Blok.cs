namespace ApartmanApp.Core.Entities;

public class Blok
{
    public int Id { get; set; }

    /// <summary>Blok adı — örn. "A", "B", "3. Blok"</summary>
    public string Ad { get; set; } = string.Empty;

    public ICollection<Daire> Daireler { get; set; } = new List<Daire>();
}
