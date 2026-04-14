using ApartmanApp.Core.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ApartmanApp.Data.Configurations;

public class OtomatikAidatConfiguration : IEntityTypeConfiguration<OtomatikAidat>
{
    public void Configure(EntityTypeBuilder<OtomatikAidat> builder)
    {
        builder.HasKey(o => o.Id);

        builder.Property(o => o.Tutar)
            .IsRequired()
            .HasPrecision(10, 2);

        // Her kullanıcı için yalnızca bir otomatik aidat kaydı olsun
        builder.HasIndex(o => o.KullaniciId).IsUnique();

        builder.HasOne(o => o.Kullanici)
            .WithMany()
            .HasForeignKey(o => o.KullaniciId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
