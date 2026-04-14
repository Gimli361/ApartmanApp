using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace ApartmanApp.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddArizaFoto : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ArizaFotolar",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ArizaId = table.Column<int>(type: "integer", nullable: false),
                    DosyaAdi = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    DosyaYolu = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    DosyaBoyutu = table.Column<long>(type: "bigint", nullable: false),
                    YuklemeTarihi = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ArizaFotolar", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ArizaFotolar_Arizalar_ArizaId",
                        column: x => x.ArizaId,
                        principalTable: "Arizalar",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ArizaFotolar_ArizaId",
                table: "ArizaFotolar",
                column: "ArizaId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ArizaFotolar");
        }
    }
}
