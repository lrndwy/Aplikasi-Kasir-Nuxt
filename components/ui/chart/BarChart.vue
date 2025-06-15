<template>
  <Bar :data="chartData" :options="chartOptions || defaultChartOptions" />
</template>

<script setup lang="ts">
import { Bar } from "vue-chartjs";
import {
  Chart as ChartJS,
  Title,
  Tooltip,
  Legend,
  BarElement,
  CategoryScale,
  LinearScale,
} from "chart.js";

ChartJS.register(Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale);

interface BarChartProps {
  chartData: {
    labels: string[];
    datasets: {
      label: string;
      backgroundColor: string;
      data: number[];
    }[];
  };
  chartOptions?: object;
}

const props = defineProps<BarChartProps>();

const defaultChartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      display: true,
      labels: {
        color: "rgb(156 163 175)", // gray-400
      },
    },
    tooltip: {
      callbacks: {
        label: function (context: any) {
          let label = context.dataset.label || "";
          if (label) {
            label += ": ";
          }
          if (context.parsed.y !== null) {
            label += new Intl.NumberFormat("id-ID", {
              style: "currency",
              currency: "IDR",
              minimumFractionDigits: 0,
              maximumFractionDigits: 0,
            }).format(context.parsed.y);
          }
          return label;
        },
      },
    },
  },
  scales: {
    x: {
      ticks: {
        color: "rgb(156 163 175)", // gray-400
      },
      grid: {
        color: "rgba(156, 163, 175, 0.1)", // gray-400 with transparency
      },
    },
    y: {
      ticks: {
        color: "rgb(156 163 175)", // gray-400
        callback: function (value: any) {
          return new Intl.NumberFormat("id-ID", {
            style: "currency",
            currency: "IDR",
            minimumFractionDigits: 0,
            maximumFractionDigits: 0,
          }).format(value);
        },
      },
      grid: {
        color: "rgba(156, 163, 175, 0.1)", // gray-400 with transparency
      },
    },
  },
};
</script>
