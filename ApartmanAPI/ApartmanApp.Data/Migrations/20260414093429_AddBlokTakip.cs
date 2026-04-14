using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace ApartmanApp.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddBlokTakip : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "BlokNo",
                table: "Kullanicilar",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "BlokNo",
                table: "Arizalar",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "RedNedeni",
                table: "Arizalar",
                type: "text",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "ArizaTakipler",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ArizaId = table.Column<int>(type: "integer", nullable: false),
                    KullaniciId = table.Column<int>(type: "integer", nullable: false),
                    TakipTarihi = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ArizaTakipler", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ArizaTakipler_Arizalar_ArizaId",
                        column: x => x.ArizaId,
                        principalTable: "Arizalar",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ArizaTakipler_Kullanicilar_KullaniciId",
                        column: x => x.KullaniciId,
                        principalTable: "Kullanicilar",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ArizaTakipler_ArizaId_KullaniciId",
                table: "ArizaTakipler",
                columns: new[] { "ArizaId", "KullaniciId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ArizaTakipler_KullaniciId",
                table: "ArizaTakipler",
                column: "KullaniciId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ArizaTakipler");

            migrationBuilder.DropColumn(
                name: "BlokNo",
                table: "Kullanicilar");

            migrationBuilder.DropColumn(
                name: "BlokNo",
                table: "Arizalar");

            migrationBuilder.DropColumn(
                name: "RedNedeni",
                table: "Arizalar");
        }
    }
}
