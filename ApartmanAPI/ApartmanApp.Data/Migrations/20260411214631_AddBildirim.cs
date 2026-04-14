using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace ApartmanApp.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddBildirim : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Bildirimler",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Baslik = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Icerik = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    Tip = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    AliciId = table.Column<int>(type: "integer", nullable: true),
                    GonderimTarihi = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Okundu = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Bildirimler", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Bildirimler_Kullanicilar_AliciId",
                        column: x => x.AliciId,
                        principalTable: "Kullanicilar",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Bildirimler_AliciId",
                table: "Bildirimler",
                column: "AliciId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Bildirimler");
        }
    }
}
