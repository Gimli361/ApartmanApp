using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace ApartmanApp.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddOylama : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Oylamalar",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Baslik = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Aciklama = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    BaslangicTarihi = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    BitisTarihi = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    OlusturanId = table.Column<int>(type: "integer", nullable: false),
                    AktifMi = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Oylamalar", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Oylamalar_Kullanicilar_OlusturanId",
                        column: x => x.OlusturanId,
                        principalTable: "Kullanicilar",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "OylamaSecenekler",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    OylamaId = table.Column<int>(type: "integer", nullable: false),
                    Metin = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_OylamaSecenekler", x => x.Id);
                    table.ForeignKey(
                        name: "FK_OylamaSecenekler_Oylamalar_OylamaId",
                        column: x => x.OylamaId,
                        principalTable: "Oylamalar",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "OylamaOylari",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    OylamaId = table.Column<int>(type: "integer", nullable: false),
                    SecenekId = table.Column<int>(type: "integer", nullable: false),
                    KullaniciId = table.Column<int>(type: "integer", nullable: false),
                    OyTarihi = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_OylamaOylari", x => x.Id);
                    table.ForeignKey(
                        name: "FK_OylamaOylari_Kullanicilar_KullaniciId",
                        column: x => x.KullaniciId,
                        principalTable: "Kullanicilar",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_OylamaOylari_OylamaSecenekler_SecenekId",
                        column: x => x.SecenekId,
                        principalTable: "OylamaSecenekler",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_OylamaOylari_Oylamalar_OylamaId",
                        column: x => x.OylamaId,
                        principalTable: "Oylamalar",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Oylamalar_OlusturanId",
                table: "Oylamalar",
                column: "OlusturanId");

            migrationBuilder.CreateIndex(
                name: "IX_OylamaOylari_KullaniciId",
                table: "OylamaOylari",
                column: "KullaniciId");

            migrationBuilder.CreateIndex(
                name: "IX_OylamaOylari_OylamaId_KullaniciId",
                table: "OylamaOylari",
                columns: new[] { "OylamaId", "KullaniciId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_OylamaOylari_SecenekId",
                table: "OylamaOylari",
                column: "SecenekId");

            migrationBuilder.CreateIndex(
                name: "IX_OylamaSecenekler_OylamaId",
                table: "OylamaSecenekler",
                column: "OylamaId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "OylamaOylari");

            migrationBuilder.DropTable(
                name: "OylamaSecenekler");

            migrationBuilder.DropTable(
                name: "Oylamalar");
        }
    }
}
