using ApartmanApp.Core.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ApartmanApp.Data.Configurations;

public class BildirimConfiguration : IEntityTypeConfiguration<Bildirim>
{
    public void Configure(EntityTypeBuilder<Bildirim> builder)
    {
        builder.HasKey(b => b.Id);

        builder.Property(b => b.Baslik).IsRequired().HasMaxLength(200);
        builder.Property(b => b.Icerik).IsRequired().HasMaxLength(1000);
        builder.Property(b => b.Tip).IsRequired().HasMaxLength(50);

        builder.HasOne(b => b.Alici)
            .WithMany()
            .HasForeignKey(b => b.AliciId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}
