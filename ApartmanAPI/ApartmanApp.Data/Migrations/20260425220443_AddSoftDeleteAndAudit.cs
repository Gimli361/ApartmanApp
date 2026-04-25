using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ApartmanApp.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddSoftDeleteAndAudit : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Oylamalar",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "DeletedAt",
                table: "Oylamalar",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "Oylamalar",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "Oylamalar",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Bildirimler",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "DeletedAt",
                table: "Bildirimler",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "Bildirimler",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "Bildirimler",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Arizalar",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "DeletedAt",
                table: "Arizalar",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "Arizalar",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "Arizalar",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Aidatlar",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "DeletedAt",
                table: "Aidatlar",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "Aidatlar",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "Aidatlar",
                type: "timestamp with time zone",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "Oylamalar");

            migrationBuilder.DropColumn(
                name: "DeletedAt",
                table: "Oylamalar");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "Oylamalar");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "Oylamalar");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "Bildirimler");

            migrationBuilder.DropColumn(
                name: "DeletedAt",
                table: "Bildirimler");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "Bildirimler");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "Bildirimler");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "Arizalar");

            migrationBuilder.DropColumn(
                name: "DeletedAt",
                table: "Arizalar");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "Arizalar");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "Arizalar");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "Aidatlar");

            migrationBuilder.DropColumn(
                name: "DeletedAt",
                table: "Aidatlar");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "Aidatlar");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "Aidatlar");
        }
    }
}
